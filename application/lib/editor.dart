import 'package:flutter/material.dart';

import 'backend.dart';
import 'data_model.dart';
import 'disposition.dart';
import 'saver.dart';

class Editor extends StatefulWidget {
  const Editor({ Key key, this.game, this.atom }): super(key: key);

  final CuddlyWorld game;

  final Atom atom;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(widget.atom.kindDescription, style: Theme.of(context).textTheme.headline4),
            StringField(
              label: 'Name',
              value: widget.atom.name.value,
              onChanged: (String value) { widget.atom.name.value = value; save('state.json', RootDisposition.last); },
            ),
          ],
        ),
      ),
    );
  }
}

class StringField extends StatefulWidget {
  const StringField({
    Key key,
    this.label,
    this.value,
    this.onChanged,
  }): super(key: key);

  final String label;
  final String value;
  final ValueSetter<String> onChanged;

  @override
  State<StringField> createState() => _StringFieldState();
}

class _StringFieldState extends State<StringField> {
  TextEditingController _controller;
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(StringField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 120.0,
            child: InkWell(
              onTap: () {
                _focusNode.requestFocus();
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${widget.label}:'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                focusNode: _focusNode,
                controller: _controller,
                decoration: const InputDecoration(
                  filled: true,
                  border: InputBorder.none,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}