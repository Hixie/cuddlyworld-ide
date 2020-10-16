import 'package:flutter/material.dart';

import 'backend.dart';

class Console extends StatefulWidget {
  const Console({
    Key key,
    @required this.game,
  }): super(key: key);

  final CuddlyWorld game;

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      color: Colors.black,
    );
  }
}