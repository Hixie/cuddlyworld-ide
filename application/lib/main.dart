import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import 'backend.dart';
import 'cart.dart';
import 'catalog.dart';
import 'console.dart';
import 'data_model.dart';
import 'disposition.dart';
import 'editor.dart';
import 'help.dart';
import 'saver.dart';
import 'settings.dart';
import 'templates.dart';

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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  CuddlyWorld _game;
  Terminal _terminal;
  StreamSubscription<String> _gameStream;
  TabController _tabController;

  Atom _lastCurrent;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal();
    _tabController = TabController(length: 6, vsync: this);
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
      )
        ..reportNextLogin(_reportLogin);
      _gameStream?.cancel();
      _gameStream = _game.output.listen(_handleOutput);
    }
    final Atom current = EditorDisposition.of(context).current;
    if (current != _lastCurrent) {
      _tabController.index = 0;
    }
  }

  void _reportLogin(String result) {
    ServerDisposition.of(context).resolveLogin(result);
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    return Material(
      child: Column(
        children: <Widget>[
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const <Widget>[
              Tab(text: 'Editor'),
              Tab(text: 'Templates'),
              Tab(text: 'Cart'),
              Tab(text: 'Console'),
              Tab(text: 'Settings'),
              Tab(text: 'Help'),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (BuildContext context, Widget child) {
                  switch (_tabController.index) {
                    case 0:
                      final Atom currentAtom = EditorDisposition.of(context).current;
                      if (currentAtom != null) {
                        body = Editor(key: ValueKey<Atom>(currentAtom), game: _game, atom: currentAtom);
                      } else {
                        body = Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text('Nothing selected.', style: Theme.of(context).textTheme.headline3),
                              const SizedBox(height: 28.0),
                              OutlinedButton(
                                onPressed: () {
                                  EditorDisposition.of(context).current = AtomsDisposition.of(context).add();
                                },
                                child: const Text('Create Item'),
                              ),
                            ]
                          ),
                        );
                      }
                      body = Row(
                        children: <Widget>[
                          const SizedBox(
                            width: kCatalogWidth,
                            child: Catalog(),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: body,
                            ),
                          ),
                        ],
                      );
                      break;
                    case 1:
                      body = const TemplateLibrary();
                      break;
                    case 2:
                      body = Cart(game: _game);
                      break;
                    case 3:
                      body = Console(game: _game, terminal: _terminal);
                      break;
                    case 4:
                      body = const SettingsTab();
                      break;
                    case 5:
                      body = const HelpTab();
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: body,
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }
}
