import 'package:flutter/foundation.dart';
import 'saver.dart';

abstract class Atom extends ChangeNotifier implements JsonEncodable{
  String get kindDescription;

  final ValueNotifier<String> name = ValueNotifier<String>(null);

  @override
  Map<String, Object> encode() {
    return <String, Object>{'name': name.value};
  }

  @override
  void decode(Object obj) {
    assert(obj is Map<String, Object>);
    assert((obj as Map<String, Object>)['name'] is String);
    name.value = (obj as Map<String, Object>)['name'] as String;
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