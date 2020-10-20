// JSON

/* Whole: {
    "username", String,
    "password": String,
    "selected": int (index in things+locations),
    "things": List<thing>,
    "locations": List<location>
  }

  thing: {
    "name": String
  }

  location: {
    "name": String
  }
*/

import 'dart:convert';
import 'dart:io';

abstract class JsonEncodable {
  dynamic encode();
  void decode(Object obj);
}

Future<void> save(String file, JsonEncodable encoder) async {
  await File(file).writeAsString(jsonEncode(encoder.encode()));
}

Future<void> load(String file, JsonEncodable decoder) async {
  decoder.decode(jsonDecode(await File(file).readAsString()));
}