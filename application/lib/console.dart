import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:xterm/flutter.dart';

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
  Terminal _terminal;
  StreamSubscription<String> _gameStream;
  TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal();
    _input = TextEditingController();
    _updateGameHandler();
  }

  @override
  void didUpdateWidget(Console oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.game != oldWidget.game)
      _updateGameHandler();
  }

  void _updateGameHandler() {
    _gameStream?.cancel();
    _gameStream = widget.game.output.listen(_handleOutput);
  }

  @override
  void dispose() {
    _gameStream.cancel();
    _input.dispose();
    super.dispose();
  }

  void _handleOutput(String output) {
    if (output == '\x02')
      return;
    _terminal
      ..write(output.replaceAll('\n', '\r\n').replaceAll('\x01', ''))
      ..write('\r\n');
  }
        
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: TerminalView(terminal: _terminal)),
        TextField(
          controller: _input,
          decoration: const InputDecoration(
            prefixText: '> ',
            hintText: 'look',
          ),
          onSubmitted: (String message) {
            widget.game.sendMessage(message);
            _input.clear();
          },
        ),
      ],
    );
  }
}