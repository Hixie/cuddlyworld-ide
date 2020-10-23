import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import 'atom_widget.dart';
import 'backend.dart';
import 'catalog.dart';
import 'console.dart';
import 'data_model.dart';
import 'disposition.dart';
import 'editor.dart';
import 'saver.dart';

Future<void> main() async {
  final SaveFile saveFile = SaveFile('state.json');
  final RootDisposition rootDisposition = await RootDisposition.load(saveFile);
  runApp(
    Dispositions.withRoot(
      rootDisposition: rootDisposition,
      child: const CuddlyWorldIDE(),
    ),
  );
}

class CuddlyWorldIDE extends StatelessWidget {
  const CuddlyWorldIDE({ Key key }): super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuddly World IDE',
      theme: ThemeData.light().copyWith(
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.black,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({ Key key }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  CatalogTab _mode = CatalogTab.console;

  CuddlyWorld _game;
  Terminal _terminal;
  StreamSubscription<String> _gameStream;

  @override
  void initState() {
    _terminal = Terminal();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ServerDisposition server = ServerDisposition.of(context);
    if (_game == null ||
        server.server != _game.url ||
        server.username != _game.username ||
        server.password != _game.password) {
      _game?.dispose();
      _game = CuddlyWorld(
        url: server.server,
        username: server.username,
        password: server.password,
        onLog: _handleLog,
      );
      _gameStream?.cancel();
      _gameStream = _game.output.listen(_handleOutput);
    }
  }

  void _handleOutput(String output) {
    if (output == '\x02') {
      _terminal.write('\r\n');
      return;
    }
    _terminal
      ..write(output.replaceAll('\n', '\r\n').replaceAll('\x01', ''))
      ..write('\r\n');
  }

  void _handleLog(String output) {
    _terminal
      ..write('\x1B[31m')
      ..write(output.replaceAll('\n', '\r\n'))
      ..write('\x1B[0m\r\n');
  }

  @override
  void dispose() {
    _gameStream.cancel();
    _game.dispose();
    _terminal.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_mode) {
      case CatalogTab.items:
      case CatalogTab.locations:
        final Atom currentAtom = EditorDisposition.of(context).current;
        if (currentAtom != null) {
          body = Editor(key: ValueKey<Atom>(currentAtom), game: _game, atom: currentAtom);
        } else {
          body = const Center(child: Text('Nothing selected.'));
        }
        break;
      case CatalogTab.console:
        body = Console(game: _game, terminal: _terminal);
        break;
    }
    return Scaffold(
      body: Center(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: kCatalogWidth,
              child: Catalog(
                initialTab: _mode,
                onTabSwitch: (CatalogTab tab) {
                  setState(() { _mode = tab; });
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
