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
      } on FormatException catch(e)  {
        print('"$e" encountered while decoding savefile; backing up to ${_file.path}.backup and clearing savefile');
        File('${_file.path}.backup').writeAsStringSync(jsonFile);
        unawaited(_file.delete());
      }
    }
  }
}
