import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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

  set loginData(LoginData value) {
    if (value == loginData) {
      return;
    }
    _username = value.username;
    _password = value.password;
    notifyListeners();
  }

  LoginData get loginData => LoginData(username, password);

  String get password => _password;
  String _password = '';
  set password(String value) {
    if (value == password) {
      return;
    }
    _password = value;
    notifyListeners();
  }

  static ServerDisposition of(BuildContext context) =>
      _of<ServerDisposition>(context);
}

T _of<T extends Listenable>(BuildContext context) {
  return context.dependOnInheritedWidgetOfExactType<_Disposition<T>>().notifier;
}

class _Disposition<T extends Listenable> extends InheritedNotifier<T> {
  const _Disposition({Key key, T disposition, Widget child})
      : super(key: key, notifier: disposition, child: child);
}

class Dispositions extends StatelessWidget {
  const Dispositions({
    Key key,
    @required this.serverDisposition,
    @required this.child,
  }) : super(key: key);

  final ServerDisposition serverDisposition;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Disposition<ServerDisposition>(
      disposition: serverDisposition,
      child: child,
    );
  }
}

@immutable
class LoginData {
  const LoginData(this.username, this.password);
  final String username;
  final String password;

  @override
  bool operator ==(Object other) =>
      other is LoginData &&
      other.username == username &&
      other.password == password;
  // TODO(tree): implement hashCode

  @override
  int hashCode => hashValues(username, password);
}
