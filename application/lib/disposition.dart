import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'data_model.dart';
import 'saver.dart';

class RootDisposition extends ChangeNotifier implements JsonEncodable {
  RootDisposition(this.saveFile) {
    _serverDisposition = ServerDisposition(this);
    _thingsDisposition = ThingsDisposition(this);
    _locationsDisposition = LocationsDisposition(this);
    _editorDisposition = EditorDisposition(this);
  }

  final SaveFile saveFile;
  ServerDisposition get serverDisposition => _serverDisposition;
  ServerDisposition _serverDisposition;
  ThingsDisposition get thingsDisposition => _thingsDisposition;
  ThingsDisposition _thingsDisposition;
  LocationsDisposition get locationsDisposition => _locationsDisposition;
  LocationsDisposition _locationsDisposition;
  EditorDisposition get editorDisposition => _editorDisposition;
  EditorDisposition _editorDisposition;

  static Future<RootDisposition> load(SaveFile saveFile) async {
    final RootDisposition result = RootDisposition(saveFile);
    await saveFile.load(result);
    return result;
  }

  @override
  Map<String, Object> encode() {
    return <String, Object>{
      'server': serverDisposition.encode(),
      'things': thingsDisposition.encode(), 
      'locations': locationsDisposition.encode(),
      'editor': editorDisposition.encode(),
    };
  }

  void didChange() {
    saveFile.save(this);
  }

  Atom lookupAtom(String identifier) {
    final List<Atom> matches = <Atom>[
      ...thingsDisposition.atoms.where((Atom atom) => atom.name.value == identifier),
      ...locationsDisposition.atoms.where((Atom atom) => atom.name.value == identifier),
    ];
    if (matches.length != 1)
      return null;
    return matches.single;
  }

  @override
  void decode(Object object) {
    assert(object is Map<String, Object>);
    final Map<String, Object> map = object as Map<String, Object>;
    assert(map['server'] is Map<String, Object>);
    serverDisposition.decode(map['server'] as Map<String, Object>);
    assert(map['things'] is List<Object>);
    thingsDisposition.decode(map['things'] as List<Object>);
    assert(map['locations'] is List<Object>);
    locationsDisposition.decode(map['locations'] as List<Object>);
    assert(map['editor'] is Map<String, Object>);
    editorDisposition.decode(map['editor'] as Map<String, Object>);
    thingsDisposition.resolveIdentifiers(lookupAtom);
    locationsDisposition.resolveIdentifiers(lookupAtom);
  }
}

abstract class ChildDisposition extends ChangeNotifier {
  ChildDisposition(this.parent);

  final RootDisposition parent;

  @override void notifyListeners() {
    super.notifyListeners();
    parent.didChange();
  }
}

class ServerDisposition extends ChildDisposition {
  ServerDisposition(RootDisposition parent) : super(parent);

  String get server => _server;
  String _server = 'ws://damowmow.com:10000';
  set server(String value) {
    if (value == server) {
      return;
    }
    _server = value;
    notifyListeners();
  }

  String get username => _username;
  String _username = '';
  set username(String value) {
    if (value == username) {
      return;
    }
    _username = value;
    notifyListeners();
  }

  String get password => _password;
  String _password = '';
  set password(String value) {
    if (value == password) {
      return;
    }
    _password = value;
    notifyListeners();
  }

  void setLoginData(String username, String password) {
    if (username == _username && password == _password)
      return;
    _username = username;
    _password = password;
    notifyListeners();
  }

  Map<String, String> encode() {
    return <String, String>{'server': server, 'username': username, 'password': password};
  }
  
  void decode(Map<String, Object> object) {
    assert(object['server'] is String);
    assert(object['username'] is String);
    assert(object['password'] is String);
    _server = object['server'] as String;
    _username = object['username'] as String;
    _password = object['password'] as String;
    notifyListeners();
  }

  static ServerDisposition of(BuildContext context) => _of<ServerDisposition>(context);
}

abstract class AtomDisposition<T extends Atom> extends ChildDisposition implements AtomParent {
  AtomDisposition(RootDisposition parent) : super(parent);

  Set<T> get atoms => _atoms.toSet();
  Set<T> _atoms = <T>{};

  @protected
  T newAtom();

  T add() {
    final T result = newAtom();
    _atoms.add(result);
    notifyListeners();
    return result;
  }

  void remove(T atom) {
    assert(_atoms.contains(atom));
    _atoms.remove(atom);
    notifyListeners();
  }

  List<Object> encode() {
    return atoms.map((T atom) => atom.encode()).toList();
  }

  void decode(List<Object> object) {
    _atoms = object.map<T>((Object atom) {
      assert(atom is Map<String, Object>);
      return newAtom()
        ..decode(atom as Map<String, Object>);
    }).toSet();
    notifyListeners();
  }

  void resolveIdentifiers(AtomLookupCallback lookupCallback) {
    for (final T atom in atoms)
      atom.resolveIdentifiers(lookupCallback);
  }

  @override
  void didChange() {
    parent.didChange();
  }
}

class ThingsDisposition extends AtomDisposition<Thing> {
  ThingsDisposition(RootDisposition parent) : super(parent);

  @override
  Thing newAtom() => Thing(this);

  static ThingsDisposition of(BuildContext context) => _of<ThingsDisposition>(context);
}

class LocationsDisposition extends AtomDisposition<Location> {
  LocationsDisposition(RootDisposition parent) : super(parent);

  @override
  Location newAtom() => Location(this);

  static LocationsDisposition of(BuildContext context) => _of<LocationsDisposition>(context);
}

class EditorDisposition extends ChildDisposition {
  EditorDisposition(RootDisposition parent) : super(parent);

  @override void notifyListeners() {
    super.notifyListeners();
    parent.didChange();
  }

  Atom get current => _current;
  Atom _current;
  set current(Atom value) {
    if (value == _current)
      return;
    _current = value;
    notifyListeners();
  }

  Map<String, Object> encode() {
    return <String, Object>{
      // TODO(ianh): save current
    };
  }
  
  void decode(Map<String, Object> object) {
    // TODO(ianh): restore current
  }

  static EditorDisposition of(BuildContext context) => _of<EditorDisposition>(context);
}


T _of<T extends Listenable>(BuildContext context) {
  return context.dependOnInheritedWidgetOfExactType<_Disposition<T>>().notifier;
}

class _Disposition<T extends Listenable> extends InheritedNotifier<T> {
  const _Disposition({Key key, T disposition, Widget child}): super(key: key, notifier: disposition, child: child);
}

class Dispositions extends StatelessWidget {
  const Dispositions({
    Key key,
    @required this.rootDisposition,
    @required this.serverDisposition,
    @required this.thingsDisposition,
    @required this.locationsDisposition,
    @required this.editorDisposition,
    @required this.child,
  }) : super(key: key);

  Dispositions.withRoot({
    Key key,
    @required this.rootDisposition,
    @required this.child,
  }) : serverDisposition = rootDisposition.serverDisposition,
       thingsDisposition = rootDisposition.thingsDisposition,
       locationsDisposition = rootDisposition.locationsDisposition,
       editorDisposition = rootDisposition.editorDisposition,
       super(key: key);

  final RootDisposition rootDisposition;
  final ServerDisposition serverDisposition;
  final ThingsDisposition thingsDisposition;
  final LocationsDisposition locationsDisposition;
  final EditorDisposition editorDisposition;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Disposition<RootDisposition>(
      disposition: rootDisposition,
      child: _Disposition<ServerDisposition>(
        disposition: serverDisposition,
        child: _Disposition<ThingsDisposition>(
          disposition: thingsDisposition,
          child: _Disposition<LocationsDisposition>(
            disposition: locationsDisposition,
            child: _Disposition<EditorDisposition>(
              disposition: editorDisposition,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
