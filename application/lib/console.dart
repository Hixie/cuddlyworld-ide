import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import 'backend.dart';
import 'dialogs.dart';

class Console extends StatefulWidget {
  const Console({
    Key? key,
    required this.game,
    required this.terminal,
  }) : super(key: key);

  final CuddlyWorld game;
  final Terminal terminal;

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  late final TextEditingController _input;

  List<String> history = <String>[];
  int? index;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
    actions = <Type, Action<Intent>>{
      HistoryUpIntent:
          CallbackAction<HistoryUpIntent>(onInvoke: (HistoryUpIntent _) {
        index ??= history.length;
        if (index! > 1) {
          index = index! - 1;
        }
        setState(() {
          _input.text = history[index!];
        });
        return null;
      }),
      HistoryDownIntent:
          CallbackAction<HistoryDownIntent>(onInvoke: (HistoryDownIntent _) {
        if (index != null && index! < history.length - 1) {
          index = index! + 1;
          setState(() {
            _input.text = history[index!];
          });
        }
        return null;
      })
    };
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    widget.game.sendMessage(_input.text).catchError(
          (Object error) => '',
          test: (Object error) => error is ConnectionLostException,
        );
    history.add(_input.text);
    _input.clear();
    index = null;
  }

  Widget _buildChip(String command) {
    return ActionChip(
      label: Text(command),
      onPressed: () {
        widget.game.sendMessage(command).catchError(
              (Object error) => '',
              test: (Object error) => error is ConnectionLostException,
            );
      },
    );
  }
  
  void generateTeleportDialog() {
    widget.game.sendMessage('debug locations').then((String result) {
      final Iterable<String> locations = result
          .split('\n')
          .skip(1)
          .takeWhile((String line) => line.isNotEmpty)
          .map((String line) => line.substring(3));
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return BoilerplateDialog(
            title: 'Teleport to:',
            children: _addVerticalPadding(locations
                .map(
                  (String location) => ActionChip(
                    label: Text(location),
                    onPressed: () {
                      widget.game
                          .sendMessage('debug teleport $location')
                          .catchError(
                            (Object error) => '',
                            test: (Object error) =>
                                error is ConnectionLostException,
                          );
                      Navigator.pop(context);
                    },
                  ),
                )
            ).toList(),
          );
        },
      );
    });
  }

  Iterable<Widget> _addHorizontalPadding(Iterable<Widget> widgets) sync* {
    bool first = true;
    for (final Widget widget in widgets) {
      if (!first) {
        yield const SizedBox(width: 12.0);
      }
      yield widget;
      first = false;
    }
  }

  Iterable<Widget> _addVerticalPadding(Iterable<Widget> widgets) sync* {
    bool first = true;
    for (final Widget widget in widgets) {
      if (!first) {
        yield const SizedBox(height: 4.0);
      }
      yield widget;
      first = false;
    }
  }

  late Map<Type, Action<Intent>> actions;

  @override
  Widget build(BuildContext context) {
    final Map<LogicalKeySet, Intent> shortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.arrowUp): HistoryUpIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowDown): HistoryDownIntent(),
    };
    return Column(
      children: <Widget>[
        Expanded(child: TerminalView(widget.terminal)),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 32.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _addHorizontalPadding(<Widget>[
              _buildChip('look'),
              _buildChip('inventory'),
              _buildChip('north'),
              _buildChip('east'),
              _buildChip('south'),
              _buildChip('west'),
              _buildChip('take all'),
              _buildChip('drop all'),
              _buildChip('debug status'),
              ActionChip(
                label: const Text('Teleport'),
                onPressed: generateTeleportDialog,
              ),
              _buildChip('debug things'),
            ]).toList(),
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: <Widget>[
            const Text('> '),
            Expanded(
              child: Shortcuts(
                shortcuts: shortcuts,
                child: Actions(
                  actions: actions,
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'help',
                    ),
                    onEditingComplete: _send,
                  ),
                ),
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

class HistoryUpIntent extends Intent {}

class HistoryDownIntent extends Intent {}
