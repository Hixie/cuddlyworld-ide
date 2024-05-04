import 'package:flutter/material.dart';

import 'dialogs.dart';
import 'disposition.dart';

const double kSettingsWidth = 400.0;

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  TextEditingController? _username;
  TextEditingController? _password;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _username = TextEditingController(text: ServerDisposition.of(context)!.username)
      ..addListener(_rebuild);
    _password = TextEditingController(text: ServerDisposition.of(context)!.password)
      ..addListener(_rebuild);
  }

  void _rebuild() {
    setState(() { /* text editing controllers changed */ });
  }

  @override
  void dispose() {
    _username!.dispose();
    _password!.dispose();
    super.dispose();
  }

  bool get _isNew {
    final ServerDisposition serverDisposition = ServerDisposition.of(context)!;
    return serverDisposition.username != _username!.text
        || serverDisposition.password != _password!.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0, bottom: 8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kSettingsWidth, minWidth: kSettingsWidth),
            child: Text('Server configuration', style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kSettingsWidth),
            child: TextField(
              controller: _username,
              decoration: const InputDecoration(
                filled: true,
                border: InputBorder.none,
                labelText: 'Username',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kSettingsWidth),
            child: TextField(
              controller: _password,
              decoration: const InputDecoration(
                filled: true,
                border: InputBorder.none,
                labelText: 'Password',
              ),
              enableSuggestions: false,
              autocorrect: false, 
              obscureText: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kSettingsWidth),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: _isNew ? () async {
                  final String reply = await ServerDisposition.of(this.context)!.setLoginData(_username!.text, _password!.text);
                  if (!mounted) {
                    return;
                  }
                  await showMessage(this.context, 'Login', reply);
                } : null,
                child: const Text('Login'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}