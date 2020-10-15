import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

class _PendingMessage {
  _PendingMessage(this.message, this.completer);
  final String message;
  final Completer<String> completer;
}

enum CuddlyWorldStatus { connecting, connected, active, idle }

class CuddlyWorld extends ChangeNotifier {
  CuddlyWorld({
    @required this.username,
    @required this.password,
    this.url = 'ws://damowmow.com:10000',
  }) {
    _loop();
  }

  final String url;
  final String username;
  final String password;

  /// What the CuddlyWorld object is currently doing
  CuddlyWorldStatus get status => _status;
  CuddlyWorldStatus _status = CuddlyWorldStatus.idle;

  /// The message currently being sent to the server, if any
  String get currentMessage => _currentMessage;
  String _currentMessage;

  final StreamController<_PendingMessage> _controller = StreamController<_PendingMessage>();
  final Queue<Completer<String>> _pendingResponses = Queue<Completer<String>>();

  Future<void> _loop() async {
    WebSocket socket;
    StringBuffer currentResponse;
    await for (final _PendingMessage message in _controller.stream) {
      bool success = false;
      do {
        try {
          socket ??= await WebSocket.connect(url)
            ..add('$username $password')
            ..listen((Object response) {
              if (response is String) {
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
            });
          socket.add(message.message);
          _pendingResponses.add(message.completer);
          success = true;
        } on SocketException catch (error) {
          _status = CuddlyWorldStatus.connecting;
          await socket?.close();
          socket = null;
          while (_pendingResponses.isNotEmpty)
            _pendingResponses.removeFirst().completeError(error);
          currentResponse = null;
        }
      } while (!success);
    }
    await socket?.close();
  }

  Future<String> sendMessage(String message) {
    final _PendingMessage pendingMessage = _PendingMessage(message, Completer<String>());
    _controller.add(pendingMessage);
    return pendingMessage.completer.future;
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
