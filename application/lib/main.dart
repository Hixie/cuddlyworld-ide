import 'package:flutter/material.dart';

import 'backend.dart';
import 'catalog.dart';

void main() {
  runApp(const CuddlyWorldIDE());
}

class CuddlyWorldIDE extends StatelessWidget {
  const CuddlyWorldIDE({ Key key }): super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Cuddly World IDE',
      home: MainScreen(),
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
        body = Placeholder(key: ValueKey(_mode));
        break;
      case CatalogTab.locations:
        body = Placeholder(key: ValueKey(_mode));
        break;
      case CatalogTab.console:
        body = Placeholder(key: ValueKey(_mode));
        break;
    }
    return Scaffold(
      body: Center(
        child: Row(
          children: const <Widget>[
            const SizedBox(
              width: 350.0,
              child: Catalog(
                initialTab: _mode,
                onTabSwitch: (CatalogTab tab) {
                  setState(() { _mode = tab; });
                },
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
