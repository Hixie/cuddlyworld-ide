import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'data_model.dart';
import 'saver.dart' as saver;

class RootDisposition extends saver.JsonEncodable {
  RootDisposition();
  
  static RootDisposition last;

  static Future<RootDisposition> load(String filename) async {
    final RootDisposition d = RootDisposition();
    last = d;
    d.serverDisposition.parent = d;
    d.editorDisposition.parent = d;
    d.thingsDisposition.parent = d;
    d.locationsDisposition.parent = d;
    await saver.load(filename, d);
    return d;
  }

  @override
  Map<String, Object> encode() {
    return <String, Object>{
      'server': serverDisposition.encode(),
      'things': thingsDisposition.encode(), 
      'locations': locationsDisposition.encode(),
    };
  }

  void didChange() {
    saver.save('state.json', this);
  }

  @override
  void decode(Object object) {
    assert(object is Map<String, Object>);
    final Map<String, Object> map = object as Map<String, Object>;
    serverDisposition.decode(map['server']);
    thingsDisposition.decode(map['things']);
    locationsDisposition.decode(map['locations']);
  }

  final ServerDisposition serverDisposition = ServerDisposition();
  final ThingsDisposition thingsDisposition = ThingsDisposition();
  final LocationsDisposition locationsDisposition = LocationsDisposition();
  final EditorDisposition editorDisposition = EditorDisposition();
}

class ServerDisposition extends ChangeNotifier implements saver.JsonEncodable {
  ServerDisposition();

  RootDisposition parent;

  @override void notifyListeners() {
    super.notifyListeners();
    parent.didChange();
  }

  String get server => _server;
  String _server = 'ws://damowmow.com:10000';
  set server(String value) {
    if (value == server) {
      return;
    }
    _server = value;
    notifyListeners();
  }

  @override
  Map<String, String> encode() {
    return <String, String>{'server': server, 'username': username, 'password': password};
  }
  
  @override
  void decode(Object object) {
    assert(object is Map<String, Object>);
    final Map<String, Object> map = object as Map<String, Object>;
    assert(map['server'] is String);
    assert(map['username'] is String);
    assert(map['password'] is String);
    server = map['server'] as String;
    setLoginData(map['username'] as String, map['password'] as String);
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

  static ServerDisposition of(BuildContext context) => _of<ServerDisposition>(context);
}

abstract class AtomDisposition<T extends Atom> extends ChangeNotifier implements saver.JsonEncodable {

  RootDisposition parent;

  @override void notifyListeners() {
    super.notifyListeners();
    parent.didChange();
  }

  Set<T> get atoms => _atoms.toSet();
  final Set<T> _atoms = <T>{};

  @override
  List<Map<String, Object>> encode() {
    return atoms.map((T e) => e.encode()).toList();
  }

  T newAtom();

  @override
  void decode(Object object) {
    assert(object is List<Object>);
    _atoms..clear()..addAll((object as List<Object>).map((Object e) => newAtom()..decode(e)));
    notifyListeners();
  }

  void add(T atom) {
    assert(!_atoms.contains(atom));
    _atoms.add(atom);
    notifyListeners();
  }

  void remove(T atom) {
    assert(_atoms.contains(atom));
    _atoms.remove(atom);
    notifyListeners();
  }
}

class ThingsDisposition extends AtomDisposition<Thing> {
  @override
  Thing newAtom() => Thing();

  static ThingsDisposition of(BuildContext context) => _of<ThingsDisposition>(context);
}

class LocationsDisposition extends AtomDisposition<Location> {
  @override
  Location newAtom() => Location();

  static LocationsDisposition of(BuildContext context) => _of<LocationsDisposition>(context);
}

class EditorDisposition extends ChangeNotifier {
  RootDisposition parent;

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
    @required this.serverDisposition,
    @required this.thingsDisposition,
    @required this.locationsDisposition,
    @required this.editorDisposition,
    @required this.child,
  }) : super(key: key);

  Dispositions.withRoot({
    Key key,
    @required RootDisposition rootDisposition,
    @required this.child,
  }) : serverDisposition = rootDisposition.serverDisposition,
       thingsDisposition = rootDisposition.thingsDisposition,
       locationsDisposition = rootDisposition.locationsDisposition,
       editorDisposition = rootDisposition.editorDisposition,
       super(key: key);

  final ServerDisposition serverDisposition;
  final ThingsDisposition thingsDisposition;
  final LocationsDisposition locationsDisposition;
  final EditorDisposition editorDisposition;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Disposition<ServerDisposition>(
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
    );
  }
}
