import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

class _PendingMessage {
  _PendingMessage(this.message, this.completer);
  final String message;
  final Completer<String> completer;
}

class CuddlyWorldException implements Exception {
  const CuddlyWorldException(this.message, this.response);
  final String message;
  final String response; // raw data from server for debugging purposes
  @override
  String toString() => '$message\nRaw response:\n$response';
}

class ConnectionLostException implements Exception {
  const ConnectionLostException();
}

typedef LogCallback = void Function(String message);

class CuddlyWorld extends ChangeNotifier {
  CuddlyWorld({
    @required this.username,
    @required this.password,
    @required this.url,
    this.onLog,
  }) {
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

  final Map<String, List<String>> _classesCache = <String, List<String>>{};
  final Map<String, List<String>> _enumValuesCache = <String, List<String>>{};
  final Map<String, Map<String, String>> _propertiesCache = <String, Map<String, String>>{};

  Timer _autoLogout;

  Future<void> _loop() async {
    WebSocket socket, oldSocket;
    StringBuffer currentResponse;
    void disconnect() {
      if (socket != null)
        _log('Disconnected.');
      oldSocket = socket;
      socket = null;
      _classesCache.clear();
      _enumValuesCache.clear();
      _propertiesCache.clear();
      while (_pendingResponses.isNotEmpty)
        _pendingResponses.removeFirst().completeError(const ConnectionLostException());
      currentResponse = null;
      notifyListeners();
    }
    await for (final _PendingMessage message in _controller.stream) {
      _autoLogout?.cancel();
      if (oldSocket != null) {
        await oldSocket.close().timeout(const Duration(seconds: 1)).catchError((Object error) { });
        oldSocket = null;
      }
      Duration delay = const Duration(seconds: 2);
      while (socket == null) {
        try {
          assert(_pendingResponses.isEmpty);
          _log('Connecting to $url...');
          socket = await WebSocket.connect(url);
          socket
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
                  disconnect();
                },
                onError: (Object error) async {
                  _log('error: $error');
                  await socket?.close();
                  disconnect();
                }
              );
        } on SocketException catch (error) {
          // catches errors on connect
          String message = error.message;
          if (message.isEmpty)
            message = error.osError.message;
          if (message.isEmpty)
            message = 'error ${error.osError.errorCode}';
          _log(message);
          assert(_pendingResponses.isEmpty);
          await Future<void>.delayed(delay);
          if (delay < const Duration(seconds: 60))
            delay *= 2;
        }
      }
      if (message != null) {
        socket.add(message.message);
        _pendingResponses.add(message.completer);
      }
      _autoLogout = Timer(const Duration(seconds: 20), () {
        _autoLogout = null;
        disconnect();
      });
    }
    await socket?.close();
  }

  Future<String> sendMessage(String message) {
    final _PendingMessage pendingMessage = _PendingMessage(message, Completer<String>());
    _controller.add(pendingMessage);
    return pendingMessage.completer.future;
  }

  Future<List<String>> fetchClassesOf(String subclass) async {
    if (_classesCache.containsKey(subclass))
      return _classesCache[subclass];
    final String rawResult = await sendMessage('debug classes of $subclass');
    final List<String> lines = rawResult.split('\n');
    if (lines.isEmpty || lines.first != 'The following classes are known:' || lines.last != '')
      throw CuddlyWorldException('Unexpectedly unable to obtain list of classes of $subclass from server.', rawResult);
    lines
      ..removeAt(0)
      ..removeLast();
    return _classesCache[subclass] = lines.map<String>((String line) {
      if (!line.startsWith(' - '))
        throw CuddlyWorldException('Unexpectedly unable to obtain list of classes of $subclass from server; did not recognize "$line".', rawResult);
      return line.substring(3);
    }).toList();
  }

  Future<List<String>> fetchEnumValuesOf(String enumName) async {
    if (_enumValuesCache.containsKey(enumName))
      return _enumValuesCache[enumName];
    final String rawResult = await sendMessage('debug describe enum $enumName');
    final List<String> lines = rawResult.split('\n');
    if (lines.isEmpty || lines.first != 'Enum values available on $enumName:' || lines.last != '')
      throw CuddlyWorldException('Unexpectedly unable to obtain list of values of enum $enumName from server.', rawResult);
    lines
      ..removeAt(0)
      ..removeLast();
    return _enumValuesCache[enumName] = lines.map<String>((String line) {
      if (!line.startsWith(' - '))
        throw CuddlyWorldException('Unexpectedly unable to obtain list of values of enum $enumName from server; did not recognize "$line".', rawResult);
      return line.substring(3);
    }).toList();
  }

  Future<Map<String, String>> fetchPropertiesOf(String className) async {
    if (_propertiesCache.containsKey(className))
      return _propertiesCache[className];
    final String rawResult = await sendMessage('debug describe class $className');
    final List<String> lines = rawResult.split('\n');
    if (lines.isEmpty || lines.first != 'Properties available on $className:' || lines.last != '')
      throw CuddlyWorldException('Unexpectedly unable to obtain list of properties of $className from server.', rawResult);
    lines
      ..removeAt(0)
      ..removeLast();
    final Map<String, String> properties = <String, String>{};
    for (final String line in lines) {
      if (!line.startsWith(' - ') || !line.contains(': '))
        throw CuddlyWorldException('Unexpectedly unable to obtain list of properties of $className from server; did not recognize "$line".', rawResult);
      final int splitPosition = line.indexOf(': ');
      properties[line.substring(3, splitPosition)] = line.substring(splitPosition + 2);
    }
    return _propertiesCache[className] = properties;
  }

  void _log(String message) {
    if (onLog != null)
      onLog(message);
  }

  @override
  void dispose() {
    _autoLogout.cancel();
    _controller.close();
    _outputController.close();
    super.dispose();
  }
}
