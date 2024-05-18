import 'package:flutter/material.dart';

import 'data_model.dart';
import 'dialogs.dart';
import 'disposition.dart';

const double kSettingsWidth = 400.0;

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  TextEditingController? _username;
  TextEditingController? _password;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _username?.dispose();
    _password?.dispose();
    _username =
        TextEditingController(text: ServerDisposition.of(context).username)
          ..addListener(_rebuild);
    _password =
        TextEditingController(text: ServerDisposition.of(context).password)
          ..addListener(_rebuild);
    _rebuild();
    print('moo');
    _username?.dispose();
    _password?.dispose();
    _username =
        TextEditingController(text: ServerDisposition.of(context).username)
          ..addListener(_rebuild);
    _password =
        TextEditingController(text: ServerDisposition.of(context).password)
          ..addListener(_rebuild);
    _rebuild();
  }

  void _rebuild() {
    setState(() {/* text editing controllers changed */});
  }

  @override
  void dispose() {
    _username?.dispose();
    _password?.dispose();
    super.dispose();
  }

  bool get _isNew {
    final ServerDisposition serverDisposition = ServerDisposition.of(context);
    return serverDisposition.username != _username!.text ||
        serverDisposition.password != _password!.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            top: 12.0,
            left: 8.0,
            right: 8.0,
            bottom: 8.0,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: kSettingsWidth,
              minWidth: kSettingsWidth,
            ),
            child: Text(
              'Server configuration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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
                onPressed: _isNew
                    ? () async {
                        final String reply = await ServerDisposition.of(context)
                            .setLoginData(_username!.text, _password!.text);
                        if (!mounted) {
                          return;
                        }
                        await showMessage(context, 'Login', reply);
                      }
                    : null,
                child: const Text('Login'),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Dark Mode:'),
            Checkbox(
              value: RootDisposition.of(context).darkMode,
              onChanged: (bool? value) {
                RootDisposition.of(context).darkMode = value!;
              },
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kSettingsWidth),
            child: Align(
              child: OutlinedButton.icon(
                onPressed: () {
                  final AtomsDisposition atomsDisposition = AtomsDisposition.of(context);
                  final EditorDisposition editor = EditorDisposition.of(context)
                    ..current = null;
                  final List<Atom> atoms = atomsDisposition.atoms.toList();
                  for (final Atom atom in atoms) {
                    if (editor.cartHolds(atom))
                      editor.removeFromCart(atom);
                    atomsDisposition.remove(atom);
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete all locations and things'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
