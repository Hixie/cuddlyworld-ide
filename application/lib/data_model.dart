import 'package:flutter/foundation.dart';

typedef AtomLookupCallback = Atom Function(String identifier);

abstract class AtomParent {
  void didChange();
}

abstract class PropertyValue {
  Object encode();

  static PropertyValue decode(Object object) {
    if (object is String)
      return StringPropertyValue(object);
    if (object is bool)
      return BooleanPropertyValue(object);
    if (object is Map<String, Object>) {
      if (object['type'] == 'atom')
        return AtomPropertyValuePlaceholder(object['identifier'] as String);
    }
    throw FormatException('Unrecognized PropertyValue data', object);
  }

  PropertyValue resolve(AtomLookupCallback lookupCallback) => this; // ignore: avoid_returning_this
}

class StringPropertyValue extends PropertyValue {
  StringPropertyValue(this.value);
  
  final String value;
  
  @override
  Object encode() => value;
}

class BooleanPropertyValue extends PropertyValue {
  BooleanPropertyValue(this.value); // ignore: avoid_positional_boolean_parameters
  
  final bool value;
  
  @override
  Object encode() => value;
}

class AtomPropertyValue extends PropertyValue {
  AtomPropertyValue(this.value);
  
  final Atom value;
  
  @override
  Object encode() => <String, Object>{
    'type': 'atom',
    'identifier': value.name.value,
  };
}

class AtomPropertyValuePlaceholder extends PropertyValue {
  AtomPropertyValuePlaceholder(this.value);
  
  final String value;

  @override
  Object encode() => throw StateError('AtomPropertyValuePlaceholder asked to encode');

  @override
  PropertyValue resolve(AtomLookupCallback lookupCallback) {
    return AtomPropertyValue(lookupCallback(value));
  }
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

  PropertyValue operator [](String name) => _properties[name];
  final Map<String, PropertyValue> _properties = <String, PropertyValue>{};
  void operator []=(String name, PropertyValue value) {
    if (_properties[name] == value)
      return;
    _properties[name] = value;
    notifyListeners();
  }

  T ensurePropertyIs<T>(String name) {
    if (_properties[name] is T)
      return _properties[name] as T;
    return null;
  }

  void resolveIdentifiers(AtomLookupCallback lookupCallback) {
    for (final String name in _properties.keys)
      _properties[name] = _properties[name].resolve(lookupCallback);
  }

  Map<String, Object> encode() {
    return <String, Object>{
      'name': name.value,
      'className': className,
      for (String name in _properties.keys)
        '.$name': _properties[name].encode(),
    };
  }

  void decode(Map<String, Object> object) {
    assert(object['name'] is String);
    assert(object['className'] is String);
    name.value = object['name'] as String;
    _className = object['className'] as String;
    for (final String property in object.keys) {
      if (property.startsWith('.'))
        _properties[property.substring(1)] = PropertyValue.decode(object[property]);
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