import 'package:flutter/foundation.dart';

abstract class AtomParent {
  void didChange();
}

abstract class Atom extends ChangeNotifier {
  Atom(this.parent) {
    name.addListener(notifyListeners);
  }

  final AtomParent parent;

  String get kindDescription;
  String get rootClass;

  final ValueNotifier<String> name = ValueNotifier<String>('');

  String get className => _className;
  String _className = '';
  set className(String value) {
    if (value == _className)
      return;
    _className = value;
    notifyListeners();
  }

  String operator [](String name) => _properties[name];
  final Map<String, String> _properties = <String, String>{};
  void operator []=(String name, String value) {
    if (_properties[name] == value)
      return;
    _properties[name] = value;
    notifyListeners();
  }

  Map<String, Object> encode() {
    return <String, Object>{
      'name': name.value,
      'className': className,
      for (String name in _properties.keys)
        '.$name': _properties[name],
    };
  }

  void decode(Map<String, Object> object) {
    assert(!object.values.any((Object value) => value is! String));
    name.value = object['name'] as String;
    _className = object['className'] as String;
    for (final String property in object.keys) {
      if (property.startsWith('.'))
        _properties[property.substring(1)] = object[property] as String;
    }
    notifyListeners();
  }

  @override void notifyListeners() {
    super.notifyListeners();
    parent.didChange();
  }

  @override
  void dispose() {
    name
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}

class Thing extends Atom {
  Thing(AtomParent parent): super(parent);

  @override
  String get kindDescription => 'Thing';

  @override
  String get rootClass => 'TThing';
}

class Location extends Atom {
  Location(AtomParent parent): super(parent);

  @override
  String get kindDescription => 'Location';

  @override
  String get rootClass => 'TLocation';
}