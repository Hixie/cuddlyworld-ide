import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class JsonEncodable {
  Object encode();
  void decode(Object? object);
}

class SaveFile {
  SaveFile(String filename) : _file = File(filename);

  final File _file;

  Future<void> save(JsonEncodable root) async {
    await _file.writeAsString(json.encode(root.encode()));
  }

  Future<void> load(JsonEncodable root) async {
    if (await _file.exists()) {
      final String jsonFile = await _file.readAsString();
      try {
        root.decode(json.decode(jsonFile));
      } catch (e, stack) { // ignore: avoid_catches_without_on_clauses
        await _file.rename('${_file.path}.broken.${DateTime.timestamp().microsecondsSinceEpoch}');
        print('$e\n$stack'); // ignore: avoid_print
      }
    }
  }
}
