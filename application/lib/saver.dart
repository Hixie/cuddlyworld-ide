import 'dart:convert';
import 'dart:io';

abstract class JsonEncodable {
  Object encode();
  void decode(Object object);
}

Future<void> save(String file, JsonEncodable encoder) async {
  await File(file).writeAsString(json.encode(encoder.encode()));
}

Future<void> load(String file, JsonEncodable decoder) async {
  decoder.decode(json.decode(await File(file).readAsString()));
}