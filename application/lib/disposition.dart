import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'data_model.dart';
import 'saver.dart';

class RootDisposition extends ChangeNotifier implements JsonEncodable {
  RootDisposition(this.saveFile) {
    _serverDisposition = ServerDisposition(this);
    _atomsDisposition = AtomsDisposition(this);
    _editorDisposition = EditorDisposition(this);
  }
  
  Timer _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  final SaveFile saveFile;
  ServerDisposition get serverDisposition => _serverDisposition;
  ServerDisposition _serverDisposition;
  AtomsDisposition get atomsDisposition => _atomsDisposition;
  AtomsDisposition _atomsDisposition;
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
      'atoms': atomsDisposition.encode(), 
      'editor': editorDisposition.encode(),
    };
  }

  void didChange() {
    _timer ??= Timer(const Duration(seconds: 1), () {
      saveFile.save(this);
      _timer = null; 
    });
  }

  Atom lookupAtom(String identifier, { Atom ignore }) {
    final List<Atom> matches = atomsDisposition.atoms
      .where((Atom atom) => atom != ignore && atom.identifier.identifier == identifier)
      .toList();
    if (matches.isEmpty)
      return null;
    assert(matches.length == 1);
    return matches.single;
  }

  static const String unnamed = 'unnamed';

  Identifier getNewIdentifier({ String name = unnamed, Atom ignore }) {
    int index = 0;
    while (lookupAtom('${name}_$index', ignore: ignore) != null)
      index += 1;
    return Identifier(name, index);
  }
  
  @override
  void decode(Object object) {
    assert(object is Map<String, Object>);
    final Map<String, Object> map = object as Map<String, Object>;
    assert(map['server'] is Map<String, Object>);
    serverDisposition.decode(map['server'] as Map<String, Object>);
    assert(map['atoms'] is List<Object>);
    atomsDisposition.decode(map['atoms'] as List<Object>);
    assert(map['editor'] is Map<String, Object>);
    atomsDisposition.resolveIdentifiers(lookupAtom);
    editorDisposition.decode(map['editor'] as Map<String, Object>, lookupAtom);
  }

  static RootDisposition of(BuildContext context) => _of<RootDisposition>(context);
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

class AtomsDisposition extends ChildDisposition implements AtomParent {
  AtomsDisposition(RootDisposition parent) : super(parent);

  Set<Atom> get atoms => _atoms.toSet();
  Set<Atom> _atoms = <Atom>{};

  @protected
  Atom newAtom() => Atom(this);

  Atom add() {
    final Atom result = newAtom();
    _atoms.add(result);
    notifyListeners();
    return result;
  }

  void remove(Atom atom) {
    assert(_atoms.contains(atom));
    _atoms.remove(atom);
    notifyListeners();
  }

  List<Object> encode() {
    return atoms.map((Atom atom) => atom.encode()).toList();
  }

  void decode(List<Object> object) {
    _atoms = object.map<Atom>((Object atom) {
      assert(atom is Map<String, Object>);
      return newAtom()
        ..decode(atom as Map<String, Object>);
    }).toSet();
    notifyListeners();
  }

  void resolveIdentifiers(AtomLookupCallback lookupCallback) {
    for (final Atom atom in atoms)
      atom.resolveIdentifiers(lookupCallback);
  }

  @override
  Identifier getNewIdentifier() => parent.getNewIdentifier();

  @override
  void didChange() {
    parent.didChange();
  }

  static AtomsDisposition of(BuildContext context) => _of<AtomsDisposition>(context);
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
      'current': (current != null) ? current.identifier.identifier : '',
    };
  }
  
  void decode(Map<String, Object> object, AtomLookupCallback lookupCallback) {
    assert(object['current'] is String);
    final String currentIdentifier = object['current'] as String;
    if (currentIdentifier.isNotEmpty)
      current = lookupCallback(currentIdentifier);
    else
      current = null;
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
    @required this.atomsDisposition,
    @required this.editorDisposition,
    @required this.child,
  }) : super(key: key);

  Dispositions.withRoot({
    Key key,
    @required this.rootDisposition,
    @required this.child,
  }) : serverDisposition = rootDisposition.serverDisposition,
       atomsDisposition = rootDisposition.atomsDisposition,
       editorDisposition = rootDisposition.editorDisposition,
       super(key: key);

  final RootDisposition rootDisposition;
  final ServerDisposition serverDisposition;
  final AtomsDisposition atomsDisposition;
  final EditorDisposition editorDisposition;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Disposition<RootDisposition>(
      disposition: rootDisposition,
      child: _Disposition<ServerDisposition>(
        disposition: serverDisposition,
        child: _Disposition<AtomsDisposition>(
          disposition: atomsDisposition,
          child: _Disposition<EditorDisposition>(
            disposition: editorDisposition,
            child: child,
          ),
        ),
      ),
    );
  }
}
