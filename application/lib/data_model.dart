import 'package:flutter/foundation.dart';
import 'saver.dart';

abstract class Atom extends ChangeNotifier implements JsonEncodable{
  String get kindDescription;

  final ValueNotifier<String> name = ValueNotifier<String>(null);

  @override
  Map<String, String> encode() {
    return <String, String>{'name': name.value};
  }

  @override
  void decode(Object obj) {
    name.value = (obj as Map<String, String>)[name];
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}

class Thing extends Atom {
  @override
  String get kindDescription => 'Thing';
}

class Location extends Atom {
  @override
  String get kindDescription => 'Location';
}