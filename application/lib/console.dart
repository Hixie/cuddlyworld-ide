import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:xterm/flutter.dart';

import 'backend.dart';

class Console extends StatefulWidget {
  const Console({
    Key key,
    @required this.game,
    @required this.terminal,
  }): super(key: key);

  final CuddlyWorld game;
  final Terminal terminal;

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    widget.game.sendMessage(_input.text);
    _input.clear();
  }

  Widget _buildChip(String command) {
    return ActionChip(
      label: Text(command),
      onPressed: () {
        widget.game.sendMessage(command);
      },
    );
  }

  Iterable<Widget> _addPadding(Iterable<Widget> widgets) sync* {
    bool first = true;
    for (final Widget widget in widgets) {
      if (!first)
        yield const SizedBox(width: 12.0);
      yield widget;
      first = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: TerminalView(terminal: widget.terminal)),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 32.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _addPadding(<Widget>[
              _buildChip('look'),
              _buildChip('inventory'),
              _buildChip('north'),
              _buildChip('east'),
              _buildChip('south'),
              _buildChip('west'),
              _buildChip('take all'),
              _buildChip('drop all'),
              _buildChip('debug status'),
              _buildChip('debug locations'),
              _buildChip('debug things'),
            ]).toList(),
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: <Widget>[
            const Text('> '),
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'help',
                ),
                onEditingComplete: _send,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _send,
            ),
          ],
        ),
      ],
    );
  }
}