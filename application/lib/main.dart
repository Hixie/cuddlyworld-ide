import 'package:flutter/material.dart';

import 'backend.dart';
import 'catalog.dart';
import 'console.dart';

void main() {
  runApp(const CuddlyWorldIDE());
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
  CuddlyWorld _game;
  CatalogTab _mode = CatalogTab.console;

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
