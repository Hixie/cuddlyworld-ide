import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

class _PendingMessage {
  _PendingMessage(this.message, this.completer);
  final String message;
  final Completer<String> completer;
}

typedef LogCallback = void Function(String message);

class CuddlyWorld extends ChangeNotifier {
  CuddlyWorld({
    @required this.username,
    @required this.password,
    @required this.url,
    this.onLog,
  }) {
    _log('connecting to $url...');
    _controller.add(null);
    _loop();
  }

  final String url;
  final String username;
  final String password;
  final LogCallback onLog;

  /// The message currently being sent to the server, if any
  String get currentMessage => _currentMessage;
  String _currentMessage;

  Stream<String> get output => _outputController.stream;
  final StreamController<String> _outputController = StreamController<String>.broadcast();

  final StreamController<_PendingMessage> _controller = StreamController<_PendingMessage>();
  final Queue<Completer<String>> _pendingResponses = Queue<Completer<String>>();

  Future<void> _loop() async {
    WebSocket socket;
    StringBuffer currentResponse;
    await for (final _PendingMessage message in _controller.stream) {
      socket ??= await WebSocket.connect(url)
        ..add('$username $password')
        ..listen(
            (Object response) {
              if (response is String) {
                _outputController.add(response);
                if (response.startsWith('\x01> ')) {
                  assert(currentResponse == null);
                  assert(_pendingResponses.isNotEmpty);
                  currentResponse = StringBuffer();
                  // TODO(ianh): could check that the echo is what we expect, too
                } else if (currentResponse != null) {
                  if (response != '\x02') {
                    currentResponse.writeln(response);
                  } else {
                    _pendingResponses.removeFirst().complete(currentResponse.toString());
                    currentResponse = null;
                  }
                }
              }
            },
            onDone: () {
              _log('Disconnected.');
              socket = null;
            },
            onError: (Object error) async {
              _log('error: $error');
              await socket?.close();
              socket = null;
              while (_pendingResponses.isNotEmpty)
                _pendingResponses.removeFirst().completeError(error);
              currentResponse = null;
            }
          );
      if (message != null) {
        socket.add(message.message);
        _pendingResponses.add(message.completer);
      }
    }
    await socket?.close();
  }

  Future<String> sendMessage(String message) {
    final _PendingMessage pendingMessage = _PendingMessage(message, Completer<String>());
    _controller.add(pendingMessage);
    return pendingMessage.completer.future;
  }

  void _log(String message) {
    if (onLog != null)
      onLog(message);
  }

  @override
  void dispose() {
    _controller.close();
    _outputController.close();
    super.dispose();
  }
}
