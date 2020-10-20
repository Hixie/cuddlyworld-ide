import 'package:flutter/material.dart';

import 'backend.dart';
import 'data_model.dart';

class Editor extends StatefulWidget {
  const Editor({ Key key, this.game, this.atom }): super(key: key);

  final CuddlyWorld game;

  final Atom atom;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  TextEditingController _name;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ListBody(
        children: <Widget>[
          Text('${widget.atom}'),
        ],
      ),
    );
  }
}