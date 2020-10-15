import 'package:flutter/material.dart';
import 'catalog.dart';

void main() {
  runApp(const CuddlyWorldIDE());
}

class CuddlyWorldIDE extends StatelessWidget {
  const CuddlyWorldIDE({ Key key }): super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: <Widget>[
            Container(
              color: Colors.red,
            ),
            const Expanded(
              child: Catalog(),
            ),
          ],
        ),
      ),
    );
  }
}
