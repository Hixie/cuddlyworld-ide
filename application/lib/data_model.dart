import 'package:flutter/foundation.dart';

typedef AtomLookupCallback = Atom Function(String identifier);

String escapeSingleQuotes(String raw) {
  return raw.replaceAll(r'\', r'\\').replaceAll(r"'", r"\'");
}

String escapeDoubleQuotes(String raw) {
  return raw.replaceAll(r'\', r'\\').replaceAll(r'"', r'\"');
}

abstract class AtomParent {
  void didChange();
  Identifier getNewIdentifier();
}

abstract class PropertyValue {
  Object encode();
  String encodeForServer(String key, Set<Atom> serialized);

  static PropertyValue decode(Object object) {
    if (object is String)
      return StringPropertyValue(object);
    if (object is bool)
      return BooleanPropertyValue(object);
    if (object is Map<String, Object>) {
      if (object['type'] == 'atom') {
        assert(object['identifier'] is String);
        return AtomPropertyValuePlaceholder(object['identifier'] as String);
      }
      if (object['type'] == 'enum') {
        assert(object['value'] is String);
        return EnumPropertyValue(object['value'] as String);
      }
      if (object['type'] == 'child*') {
        assert(object['children'] is List<Object>, 'not a list: $object');
        assert(!(object['children'] as List<Object>).any((Object child) {
          return !(child is Map<String, Object> &&
                   child['position'] is String &&
                   (!child.containsKey('identifier') || child['identifier'] is String));
        }));
        return ChildrenPropertyValuePlaceholder(
          (object['children'] as List<Object>).map<PositionedAtomPlaceholder>((Object child) {
            final Map<String, Object> map = child as Map<String, Object>;
            return PositionedAtomPlaceholder(map['position'] as String, map['identifier'] as String);
          }).toList(),
        );
      }
      if (object['type'] == 'landmark*') {
        assert(object['children'] is List<Object>, 'not a list: $object');
        assert(!(object['children'] as List<Object>).any((Object child) {
          return !(child is Map<String, Object> &&
                   child['direction'] is String &&
                   (!child.containsKey('identifier') || child['identifier'] is String) &&
                   child['options'] is List<Object> &&
                   !(child['options'] as List<Object>).any((Object value) => value is! String));
        }));
        return LandmarksPropertyValuePlaceholder(
          (object['children'] as List<Object>).map<LandmarkPlaceholder>((Object child) {
            final Map<String, Object> map = child as Map<String, Object>;
            return LandmarkPlaceholder(map['direction'] as String, map['identifier'] as String, (map['options'] as List<Object>).cast<String>().toSet());
          }).toList(),
        );
      }
    }
    throw FormatException('Unrecognized PropertyValue data ($object)', object);
  }

  PropertyValue resolve(AtomLookupCallback lookupCallback) => this; // ignore: avoid_returning_this
}

class StringPropertyValue extends PropertyValue {
  StringPropertyValue(this.value);
  
  final String value;
  
  @override
  Object encode() => value;

  @override
  String encodeForServer(String key, Set<Atom> serialized) => '$key: "${escapeDoubleQuotes(value)}"; ';
}

class EnumPropertyValue extends PropertyValue {
  EnumPropertyValue(this.value);
  
  final String value;
  
  @override
  Object encode() => <String, Object>{
    'type': 'enum',
    'value': value,
  };

  @override
  String encodeForServer(String key, Set<Atom> serialized) => '$key: $value; ';
}

class BooleanPropertyValue extends PropertyValue {
  BooleanPropertyValue(this.value); // ignore: avoid_positional_boolean_parameters
  
  final bool value;
  
  @override
  Object encode() => value;

  @override
  String encodeForServer(String key, Set<Atom> serialized) => '$key: $value; ';
}

class AtomPropertyValue extends PropertyValue {
  AtomPropertyValue(this.value);
  
  final Atom value;
  
  @override
  Object encode() => <String, Object>{
    'type': 'atom',
    'identifier': value.identifier.identifier,
  };
  
  @override
  String encodeForServer(String key, Set<Atom> serialized) => '$key: ${value.encodeForServer(serialized)}; ';
}

class AtomPropertyValuePlaceholder extends PropertyValue {
  AtomPropertyValuePlaceholder(this.value);
  
  final String value;

  @override
  Object encode() => throw StateError('AtomPropertyValuePlaceholder asked to encode');

  @override
  String encodeForServer(String key, Set<Atom> serialized) => throw StateError('AtomPropertyValuePlaceholder asked to encode for server');

  @override
  PropertyValue resolve(AtomLookupCallback lookupCallback) {
    return AtomPropertyValue(lookupCallback(value));
  }
}

class ChildrenPropertyValue extends PropertyValue {
  ChildrenPropertyValue(this.value);
  
  final List<PositionedAtom> value;
  
  @override
  Object encode() => <String, Object>{
    'type': 'child*',
    'children': value.map<Map<String, Object>>((PositionedAtom entry) => entry.encode()).toList(),
  };

  @override
  String encodeForServer(String key, Set<Atom> serialized) {
    final StringBuffer buffer = StringBuffer();
    for (final PositionedAtom positionedAtom in value) {
      buffer.write('$key: ${positionedAtom.encodeForServer(serialized)}; ');
    }
    return buffer.toString();
  }
}

class ChildrenPropertyValuePlaceholder extends PropertyValue {
  ChildrenPropertyValuePlaceholder(this.value);
  
  final List<PositionedAtomPlaceholder> value;

  @override
  Object encode() => throw StateError('ChildrenPropertyValuePlaceholder asked to encode');

  @override
  String encodeForServer(String key, Set<Atom> serialized) => throw StateError('ChildrenPropertyValuePlaceholder asked to encode for server');

  @override
  PropertyValue resolve(AtomLookupCallback lookupCallback) {
    return ChildrenPropertyValue(value.map<PositionedAtom>((PositionedAtomPlaceholder entry) => entry.resolve(lookupCallback)).toList());
  }
}

class LandmarksPropertyValue extends PropertyValue {
  LandmarksPropertyValue(this.value);

  final List<Landmark> value;
  
  @override
  Object encode() => <String, Object>{
    'type': 'landmark*',
    'children': value.map<Map<String, Object>>((Landmark entry) => entry.encode()).toList(),
  };

  @override
  String encodeForServer(String key, Set<Atom> serialized) {
    final StringBuffer buffer = StringBuffer();
    for (final Landmark landmark in value) {
      buffer.write('$key: ${landmark.encodeForServer(serialized)}; ');
    }
    return buffer.toString();
  }
}

class LandmarksPropertyValuePlaceholder extends PropertyValue {
  LandmarksPropertyValuePlaceholder(this.value);
  
  final List<LandmarkPlaceholder> value;

  @override
  Object encode() => throw StateError('LandmarksPropertyValuePlaceholder asked to encode');

  @override
  String encodeForServer(String key, Set<Atom> serialized) => throw StateError('LandmarksPropertyValuePlaceholder asked to encode for server');

  @override
  PropertyValue resolve(AtomLookupCallback lookupCallback) {
    return LandmarksPropertyValue(value.map<Landmark>((LandmarkPlaceholder entry) => entry.resolve(lookupCallback)).toList());
  }
}

class PositionedAtom {
  PositionedAtom(this.position, this.atom);
  
  final String position;
  final Atom atom;

  Map<String, Object> encode() => <String, Object>{
    'position': position,
    if (atom != null)
      'identifier': atom.identifier.identifier,
  };

  String encodeForServer(Set<Atom> serialized) {
    return '$position, ${atom.encodeForServer(serialized)}';
  }
}

class PositionedAtomPlaceholder {
  PositionedAtomPlaceholder(this.position, this.identifier);

  final String position;
  final String identifier;

  PositionedAtom resolve(AtomLookupCallback lookupCallback) {
    return PositionedAtom(position, lookupCallback(identifier));
  }
}

class Landmark {
  Landmark(this.direction, this.atom, this.options);
  
  final String direction;
  final Atom atom; 
  final Set<String> options;

  Map<String, Object> encode() => <String, Object>{
    'direction': direction,
    if (atom != null)
      'identifier': atom.identifier.identifier,
    'options': options.toList(),
  };

  String encodeForServer(Set<Atom> serialized) {
    return '$direction, ${atom.encodeForServer(serialized)}, ${options.join(" ")}';
  }
}

class LandmarkPlaceholder {
  LandmarkPlaceholder(this.direction, this.identifier, this.options);

  final String direction;
  final String identifier;
  final Set<String> options;

  Landmark resolve(AtomLookupCallback lookupCallback) {
    return Landmark(direction, lookupCallback(identifier), options);
  }
}

class Identifier extends Comparable<Identifier> {
  Identifier(this.name, this.disambiguator);
  factory Identifier.split(String identifier) {
    final int position = identifier.lastIndexOf('_');
    if (position < 0)
      return Identifier(identifier, 0);
    final int disambiguator = int.tryParse(identifier.substring(position + 1));
    if (disambiguator == null)
      return Identifier(identifier, 0);
    return Identifier(identifier.substring(0, position), disambiguator);
  }
  final String name;
  final int disambiguator;
  String get identifier => '${name}_$disambiguator';

  @override
  int compareTo(Identifier other) {
    if (name == other.name)
      return disambiguator.compareTo(other.disambiguator);
    return name.compareTo(other.name);
  }
}

abstract class Atom extends ChangeNotifier {
  Atom(this.parent) {
    identifier = parent.getNewIdentifier();
  }

  final AtomParent parent;

  String get rootClass;

  Identifier get identifier => _identifier;
  Identifier _identifier; // set by constructor
  set identifier(Identifier value) {
    if (value == _identifier)
      return;
    _identifier = value;
    notifyListeners();
  }

  String get className => _className;
  String _className = '';
  set className(String value) {
    if (value == _className)
      return;
    _className = value;
    notifyListeners();
  }

  String encodeForServer(Set<Atom> serialized) {
    if (serialized.contains(this))
      return identifier.identifier;
    serialized.add(this);
    final StringBuffer buffer = StringBuffer();
    for (final String key in _properties.keys)
      buffer.write(_properties[key].encodeForServer(key, serialized));
    return 'new $className named ${identifier.identifier} { $buffer}';
  }

  PropertyValue operator [](String name) => _properties[name];
  final Map<String, PropertyValue> _properties = <String, PropertyValue>{};
  void operator []=(String name, PropertyValue value) {
    if (_properties[name] == value)
      return;
    if (value == null) {
      _properties.remove(name);
    } else {
      _properties[name] = value;
    }
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
      'identifier': identifier.identifier,
      'className': className,
      for (String name in _properties.keys)
        '.$name': _properties[name].encode(),
    };
  }

  void decode(Map<String, Object> object) {
    assert(object['identifier'] is String);
    assert(object['className'] is String);
    identifier = Identifier.split(object['identifier'] as String);
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
}

class Thing extends Atom {
  Thing(AtomParent parent): super(parent);

  @override
  String get rootClass => 'TAtom';
}

class Location extends Atom {
  Location(AtomParent parent): super(parent);

  @override
  String get rootClass => 'TLocation';
}
