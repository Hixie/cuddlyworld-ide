import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'data_model.dart';
import 'saver.dart';

class RootDisposition extends ChangeNotifier implements JsonEncodable {
  RootDisposition(this.saveFile, {required bool darkMode})
      : _darkMode = darkMode {
    _serverDisposition = ServerDisposition(this);
    _atomsDisposition = AtomsDisposition(this);
    _editorDisposition = EditorDisposition(this);
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  final SaveFile saveFile;
  ServerDisposition get serverDisposition => _serverDisposition;
  late final ServerDisposition _serverDisposition;
  AtomsDisposition get atomsDisposition => _atomsDisposition;
  late final AtomsDisposition _atomsDisposition;
  EditorDisposition get editorDisposition => _editorDisposition;
  late final EditorDisposition _editorDisposition;

  bool get darkMode => _darkMode;
  bool _darkMode;
  set darkMode(bool value) {
    if (value == _darkMode) {
      return;
    }
    _darkMode = value;
    notifyListeners();
  }

  static Future<RootDisposition> load(
    SaveFile saveFile, {
    required bool darkMode,
  }) async {
    final RootDisposition result = RootDisposition(
      saveFile,
      darkMode: darkMode,
    );
    await saveFile.load(result);
    return result;
  }

  @override
  Map<String, Object?> encode() {
    return <String, Object>{
      'server': serverDisposition.encode(),
      'atoms': atomsDisposition.encode(),
      'editor': editorDisposition.encode(),
      'darkMode': darkMode,
    };
  }

  void didChange() {
    _timer ??= Timer(const Duration(seconds: 1), () {
      saveFile.save(this);
      _timer = null;
    });
  }

  Atom? lookupAtom(String? identifier, {Atom? ignore}) {
    final List<Atom> matches = atomsDisposition.atoms
        .where((Atom atom) =>
            atom != ignore && atom.identifier!.identifier == identifier)
        .toList();
    if (matches.isEmpty) {
      return null;
    }
    assert(matches.length == 1);
    return matches.single;
  }

  static const String unnamed = 'unnamed';
  Identifier getNewIdentifier({String name = unnamed, Atom? ignore}) {
    int index = 0;
    while (lookupAtom('${name}_$index', ignore: ignore) != null) {
      index += 1;
    }
    return Identifier(name, index);
  }

  @override
  void decode(Object? object) {
    assert(object is Map<String, Object?>);
    final Map<String, Object?> map = object as Map<String, Object?>;
    assert(map['server'] is Map<String, Object?>);
    serverDisposition.decode(map['server'] as Map<String, Object?>);
    assert(map['atoms'] is List<Object?>);
    atomsDisposition
      ..decode(map['atoms'] as List<Object?>)
      ..resolveIdentifiers(lookupAtom);
    assert(map['editor'] is Map<String, Object?>);
    editorDisposition.decode(map['editor'] as Map<String, Object?>, lookupAtom);
    if (map.containsKey('darkMode')) {
      assert(map['darkMode'] is bool);
      darkMode = map['darkMode'] as bool;
    }
  }

  static RootDisposition of(BuildContext context) =>
      _of<RootDisposition>(context);
}

abstract class ChildDisposition extends ChangeNotifier {
  ChildDisposition(this.parent);

  final RootDisposition parent;

  @override
  void notifyListeners() {
    super.notifyListeners();
    parent.didChange();
  }
}

class ServerDisposition extends ChildDisposition {
  ServerDisposition(RootDisposition parent) : super(parent);

  String? get server => _server;
  String? _server = 'ws://damowmow.com:10001';
  set server(String? value) {
    if (value == server) {
      return;
    }
    _server = value;
    notifyListeners();
  }

  String? get username => _username;
  String? _username = '';
  set username(String? value) {
    if (value == username) {
      return;
    }
    _username = value;
    notifyListeners();
  }

  String? get password => _password;
  String? _password = '';
  set password(String? value) {
    if (value == password) {
      return;
    }
    _password = value;
    notifyListeners();
  }

  Completer<String>? _loginDataCompleter;

  Future<String> setLoginData(String username, String password) {
    if (username == _username && password == _password)
      return Future<String>.value('');
    _username = username;
    _password = password;
    _loginDataCompleter = Completer<String>();
    notifyListeners();
    return _loginDataCompleter!.future;
  }

  void resolveLogin(String message) {
    _loginDataCompleter?.complete(message);
  }

  Map<String, String?> encode() {
    return <String, String?>{
      'server': server,
      'username': username,
      'password': password
    };
  }

  void decode(Map<String, Object?> object) {
    assert(object['server'] is String);
    assert(object['username'] is String);
    assert(object['password'] is String);
    _server = object['server'] as String?;
    _username = object['username'] as String?;
    _password = object['password'] as String?;
    notifyListeners();
  }

  static ServerDisposition of(BuildContext context) =>
      _of<ServerDisposition>(context);
}

class AtomsDisposition extends ChildDisposition implements AtomOwner {
  AtomsDisposition(super.parent);

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
    for (final Atom atom in atoms) {
      atom.identifier =
          parent.getNewIdentifier(name: atom.identifier!.name, ignore: atom);
      _atoms.add(atom);
    }
    notifyListeners();
  }

  final Set<Atom> _crematorium = <Atom>{};

  void remove(Atom lateAtom) {
    assert(_atoms.contains(lateAtom));
    _atoms.remove(lateAtom);
    for (final Atom atom in atoms) {
      atom.deletionNotification(lateAtom);
    }
    lateAtom.disconnect();
    notifyListeners();
    _crematorium.add(lateAtom);
    lateAtom.onDead = () {
      _crematorium.remove(lateAtom);
      lateAtom.dispose();
    };
  }

  List<Object> encode() {
    return atoms.map((Atom atom) => atom.encode()).toList();
  }

  void decode(List<Object?> object) {
    _atoms = object.map<Atom>((Object? atom) {
      assert(atom is Map<String, Object?>);
      return newAtom()..decode(atom as Map<String, Object?>);
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

  static AtomsDisposition of(BuildContext context) =>
      _of<AtomsDisposition>(context);
}

class EditorDisposition extends ChildDisposition {
  EditorDisposition(RootDisposition parent) : super(parent);

  @override
  void notifyListeners() {
    super.notifyListeners();
    parent.didChange();
  }

  Atom? get current => _current;
  Atom? _current;
  set current(Atom? value) {
    if (value == _current) {
      return;
    }
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

  Map<String, Object?> encode() {
    return <String, Object>{
      'current': (current != null) ? current!.identifier!.identifier : '',
      'cart': _cart
          .map<String>((Atom atom) => atom.identifier!.identifier)
          .toList(),
    };
  }

  void decode(Map<String, Object?> object, AtomLookupCallback lookupCallback) {
    assert(object['current'] is String);
    assert(object['cart'] is List<Object?>);
    final String currentIdentifier = object['current'] as String;
    if (currentIdentifier.isNotEmpty)
      current = lookupCallback(currentIdentifier);
    else
      current = null;
    _cart
      ..clear()
      ..addAll((object['cart'] as List<Object?>).cast<String>().map(
        (String name) {
          final Atom? atom = lookupCallback(name);
          if (atom == null) {
            throw FormatException('no such atom $name');
          }
          return atom;
        },
      ));
  }

  static EditorDisposition of(BuildContext context) =>
      _of<EditorDisposition>(context);
}

T _of<T extends Listenable>(BuildContext context) {
  return context
      .dependOnInheritedWidgetOfExactType<_Disposition<T>>()!
      .notifier!;
}

class _Disposition<T extends Listenable> extends InheritedNotifier<T> {
  const _Disposition({super.key, required T disposition, required super.child})
      : super(notifier: disposition);
}

class Dispositions extends StatelessWidget {
  const Dispositions({
    Key? key,
    required this.rootDisposition,
    required this.serverDisposition,
    required this.atomsDisposition,
    required this.editorDisposition,
    required this.child,
  }) : super(key: key);

  Dispositions.withRoot({
    Key? key,
    required this.rootDisposition,
    required this.child,
  })  : serverDisposition = rootDisposition.serverDisposition,
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
