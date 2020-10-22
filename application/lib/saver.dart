import 'dart:convert';
import 'dart:io';

abstract class JsonEncodable {
  Object encode();
  void decode(Object object);
}

class SaveFile {
  SaveFile(String filename) : _file = File(filename);

  final File _file;

  Future<void> save(JsonEncodable root) async {
    await _file.writeAsString(json.encode(root.encode()));
  }

  Future<void> load(JsonEncodable root) async {
    if (await _file.exists())
      root.decode(json.decode(await _file.readAsString()));
  }
}