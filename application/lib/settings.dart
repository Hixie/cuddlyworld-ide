import 'package:flutter/material.dart';

import 'disposition.dart';

const double kSettingsWidth = 100.0;

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key key}) : super(key: key);
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  TextEditingController _username;
  TextEditingController _password;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _username = TextEditingController(text: ServerDisposition.of(context).username);
    _password = TextEditingController(text: ServerDisposition.of(context).password);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: kSettingsWidth,
            child: TextField(
              controller: _username,
              decoration: const InputDecoration(
                hintText: 'Username',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: kSettingsWidth,
            child: TextField(
              controller: _password,
              decoration: const InputDecoration(
                hintText: 'Password',
              ),
              enableSuggestions: false,
              autocorrect: false, 
              obscureText: true,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            ServerDisposition.of(context).setLoginData(_username.text, _password.text);
          },
          child: const Text('Login'),
        )
      ],
    );
  }
}