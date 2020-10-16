import 'package:flutter/material.dart';

import 'backend.dart';
import 'catalog.dart';
import 'console.dart';
import 'disposition.dart';

void main() {
  final ServerDisposition serverDisposition = ServerDisposition();
  runApp(
    Dispositions(
      serverDisposition: serverDisposition,
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

  ServerDisposition _server;
  CuddlyWorld _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _server = ServerDisposition.of(context);
    if (_game == null ||
        _server.server != _game.url ||
        _server.username != _game.username ||
        _server.password != _game.password) {
      _game?.dispose();
      _game = CuddlyWorld(
        url: _server.server,
        username: _server.username,
        password: _server.password,
      );
    }
  }

  @override
  void dispose() {
    _game?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_mode) {
      case CatalogTab.items:
        body = Placeholder(key: ValueKey<CatalogTab>(_mode), color: Colors.blue);
        break;
      case CatalogTab.locations:
        body = Placeholder(key: ValueKey<CatalogTab>(_mode), color: Colors.teal);
        break;
      case CatalogTab.console:
        body = Console(game: _game);
        break;
    }
    return Scaffold(
      body: Center(
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 350.0,
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
