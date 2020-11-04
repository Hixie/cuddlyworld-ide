import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'data_model.dart';
import 'saver.dart';

class RootDisposition extends ChangeNotifier implements JsonEncodable {
  RootDisposition(this.saveFile) {
    _serverDisposition = ServerDisposition(this);
    _atomsDisposition = AtomsDisposition(this);
    _editorDisposition = EditorDisposition(this);
    _tabDisposition = TabDisposition(this);
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
  TabDisposition get tabDisposition => _tabDisposition;
  TabDisposition _tabDisposition;

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
      'tab': tabDisposition.encode(),
    };
  }

  void didChange() {
    _timer ??= Timer(const Duration(seconds: 1), () {
      saveFile.save(this);
      _timer = null;
    });
  }

  Atom lookupAtom(String identifier, {Atom ignore}) {
    final List<Atom> matches = atomsDisposition.atoms
      .where((Atom atom) => atom != ignore && atom.identifier.identifier == identifier)
      .toList();
    if (matches.isEmpty) {
      return null;
    }
    assert(matches.length == 1);
    return matches.single;
  }

  static const String unnamed = 'unnamed';

  Identifier getNewIdentifier({ String name = unnamed, Atom ignore }) {
    int index = 0;
    while (lookupAtom('${name}_$index', ignore: ignore) != null) {
      index += 1;
    }
    return Identifier(name, index);
  }

  @override
  void decode(Object object) {
    assert(object is Map<String, Object>);
    final Map<String, Object> map = object as Map<String, Object>;
    assert(map['server'] is Map<String, Object>);
    serverDisposition.decode(map['server'] as Map<String, Object>);
    assert(map['atoms'] is List<Object>);
    atomsDisposition
      ..decode(map['atoms'] as List<Object>)
      ..resolveIdentifiers(lookupAtom);
    assert(map['editor'] is Map<String, Object>);
    editorDisposition.decode(map['editor'] as Map<String, Object>, lookupAtom);
    assert(map['tab'] is int);
    tabDisposition.decode(map['tab'] as int);
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

  Completer<String> _loginDataCompleter;

  Future<String> setLoginData(String username, String password) {
    if (username == _username && password == _password)
      return Future<String>.value();
    _username = username;
    _password = password;
    _loginDataCompleter = Completer<String>();
    notifyListeners();
    return _loginDataCompleter.future;
  }

  void resolveLogin(String message) {
    _loginDataCompleter?.complete(message);
  }

  Map<String, String> encode() {
    return <String, String>{
      'server': server,
      'username': username,
      'password': password
    };
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

class AtomsDisposition extends ChildDisposition implements AtomOwner {
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

  @override
  void didChange() {
    parent.didChange();
  }

  void addAll(List<Atom> atoms) {
    _atoms.addAll(atoms);
    notifyListeners();
  }

  void remove(Atom atom) {
    assert(_atoms.contains(atom));
    _atoms.remove(atom);
    atom.delete();
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
    for (final Atom atom in atoms) {
      atom.resolveIdentifiers(lookupCallback);
    }
  }

  @override
  Identifier getNewIdentifier() => parent.getNewIdentifier();

  static AtomsDisposition of(BuildContext context) => _of<AtomsDisposition>(context);
}

class TabDisposition extends ChildDisposition {
  TabDisposition(RootDisposition parent) : super(parent);

  int get tab => _tab;
  int _tab = 0;
  set tab(int tab) {
    _tab = tab;
    notifyListeners();
  }

  int encode() => tab;
  void decode(int tab) {
    this.tab = tab;
  }

  static TabDisposition of(BuildContext context) => _of<TabDisposition>(context);
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

  Set<Atom> get cart => _cart.toSet();
  final Set<Atom> _cart = <Atom>{};

  bool cartHolds(Atom atom) => _cart.contains(atom);

  void addToCart(Atom atom) {
    if (!_cart.contains(atom)) {
      _cart.add(atom);
      notifyListeners();
    }
  }

  void removeFromCart(Atom atom) {
    if (_cart.contains(atom)) {
      _cart.remove(atom);
      notifyListeners();
    }
  }

  Map<String, Object> encode() {
    return <String, Object>{
      'current': (current != null) ? current.identifier.identifier : '',
      'cart': _cart.map<String>((Atom atom) => atom.identifier.identifier).toList(),
    };
  }

  void decode(Map<String, Object> object, AtomLookupCallback lookupCallback) {
    assert(object['current'] is String);
    assert(object['cart'] is List<Object>);
    final String currentIdentifier = object['current'] as String;
    if (currentIdentifier.isNotEmpty)
      current = lookupCallback(currentIdentifier);
    else
      current = null;
    _cart
      ..clear()
      ..addAll((object['cart'] as List<Object>).cast<String>().map(lookupCallback));
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
    @required this.tabDisposition,
    @required this.child,
  }) : super(key: key);

  Dispositions.withRoot({
    Key key,
    @required this.rootDisposition,
    @required this.child,
  })  : serverDisposition = rootDisposition.serverDisposition,
        atomsDisposition = rootDisposition.atomsDisposition,
        editorDisposition = rootDisposition.editorDisposition,
        tabDisposition = rootDisposition.tabDisposition,
        super(key: key);

  final RootDisposition rootDisposition;
  final ServerDisposition serverDisposition;
  final AtomsDisposition atomsDisposition;
  final EditorDisposition editorDisposition;
  final TabDisposition tabDisposition;

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
            child: _Disposition<TabDisposition>(
              disposition: tabDisposition,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
