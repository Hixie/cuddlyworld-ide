import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'data_model.dart';

class RootDisposition {
  RootDisposition();

  static Future<RootDisposition> load(String filename) async {
    return RootDisposition();
  }

  final ServerDisposition serverDisposition = ServerDisposition();
  final ThingsDisposition thingsDisposition = ThingsDisposition();
  final LocationsDisposition locationsDisposition = LocationsDisposition();
  final EditorDisposition editorDisposition = EditorDisposition();
}

class ServerDisposition extends ChangeNotifier {
  ServerDisposition();

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

  static ServerDisposition of(BuildContext context) => _of<ServerDisposition>(context);
}

abstract class AtomDisposition<T extends Atom> extends ChangeNotifier {
  AtomDisposition();

  Set<T> get atoms => _atoms.toSet();
  final Set<T> _atoms = <T>{};

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
  ThingsDisposition();
  static ThingsDisposition of(BuildContext context) => _of<ThingsDisposition>(context);
}

class LocationsDisposition extends AtomDisposition<Location> {
  LocationsDisposition();
  static LocationsDisposition of(BuildContext context) => _of<LocationsDisposition>(context);
}

class EditorDisposition extends ChangeNotifier {
  EditorDisposition();

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
