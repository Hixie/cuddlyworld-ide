import 'package:flutter/foundation.dart';

typedef AtomLookupCallback = Atom? Function(String identifier);

String escapeSingleQuotes(String raw) {
  return raw.replaceAll(r'\', r'\\').replaceAll(r"'", r"\'");
}

String escapeDoubleQuotes(String raw) {
  return raw.replaceAll(r'\', r'\\').replaceAll(r'"', r'\"');
}

abstract class AtomOwner {
  void didChange();
  Identifier getNewIdentifier();
}

@immutable
abstract class PropertyValue {
  const PropertyValue();

  Object encode();

  static PropertyValue decode(Object? object) {
    if (object is String) {
      return StringPropertyValue(object);
    }
    if (object is bool) {
      return BooleanPropertyValue(object);
    }
    if (object is Map<String, Object?>) {
      if (object['type'] == 'atom') {
        assert(object['identifier'] is String);
        return AtomPropertyValuePlaceholder(object['identifier'] as String);
      }
      if (object['type'] == 'literal') {
        assert(object['value'] is String);
        return LiteralPropertyValue(object['value'] as String);
      }
      if (object['type'] == 'child*') {
        assert(object['children'] is List<Object?>, 'not a list: $object');
        assert(!(object['children'] as List<Object?>).any((Object? child) {
          return !(child is Map<String, Object?> &&
              child['position'] is String &&
              (!child.containsKey('identifier') ||
                  child['identifier'] is String));
        }));
        return ChildrenPropertyValuePlaceholder(
          (object['children'] as List<Object?>)
              .map<PositionedAtomPlaceholder>((Object? child) {
            final Map<String, Object?> map = child as Map<String, Object?>;
            return PositionedAtomPlaceholder(
                map['position'] as String?, map['identifier'] as String?);
          }).toList(),
        );
      }
      if (object['type'] == 'landmark*') {
        assert(object['children'] is List<Object?>, 'not a list: $object');
        assert(() {
          for (final Object? child in object['children'] as List<Object?>) {
            child as Map<String, Object?>;
            assert(child['direction'] is String);
            assert(!child.containsKey('identifier') || child['identifier'] is String);
            assert(child['options'] is List<Object?>);
            assert(!(child['options'] as List<Object?>).any((Object? value) => value is! String));
          }
          return true;
        }());
        return LandmarksPropertyValuePlaceholder(
          (object['children'] as List<Object?>)
              .map<LandmarkPlaceholder>((Object? child) {
            final Map<String, Object?> map = child as Map<String, Object?>;
            return LandmarkPlaceholder(
                map['direction'] as String?,
                map['identifier'] as String?,
                (map['options'] as List<Object?>).cast<String>().toSet());
          }).toList(),
        );
      }
    }
    throw FormatException('Unrecognized PropertyValue data ($object)', object);
  }

  String encodeForServerMake(String key, Set<Atom> serialized);
  String encodeForServerConnect(String from) => '';

  PropertyValue? resolve(AtomLookupCallback lookupCallback, Atom parent) =>
      this; // ignore: avoid_returning_this

  void registerChildren(Atom parent) {}
  void unregisterChildren(Atom parent) {}
  Iterable<Atom> get children sync* {}

  /// Notification that `lateAtom` is being deleted.
  ///
  /// Return true if the property should now be removed entirely.
  PropertyValue? deletionNotification(Atom lateAtom) => this;
}

class StringPropertyValue extends PropertyValue {
  const StringPropertyValue(this.value);

  final String value;

  @override
  Object encode() => value;

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) =>
      '$key: "${escapeDoubleQuotes(value)}"; ';
}

class LiteralPropertyValue extends PropertyValue {
  const LiteralPropertyValue(this.value);

  final String value;

  @override
  Object encode() => <String, Object?>{
        'type': 'literal',
        'value': value,
      };

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) =>
      '$key: $value; ';
}

class BooleanPropertyValue extends PropertyValue {
  const BooleanPropertyValue(
      this.value); // ignore: avoid_positional_boolean_parameters

  final bool value;

  @override
  Object encode() => value;

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) =>
      '$key: $value; ';
}

class AtomPropertyValue extends PropertyValue {
  const AtomPropertyValue(this.value);

  final Atom value;

  @override
  Object encode() => <String, Object>{
        'type': 'atom',
        'identifier': value.identifier!.identifier,
      };

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) =>
      '$key: ${value.encodeForServerMake(serialized)}; ';

  @override
  void registerChildren(Atom parent) {
    value.registerParent(parent);
  }

  @override
  void unregisterChildren(Atom parent) {
    value.unregisterParent(parent);
  }

  @override
  Iterable<Atom> get children sync* {
    yield value;
  }

  @override
  AtomPropertyValue? deletionNotification(Atom lateAtom) {
    if (value == lateAtom) {
      return null;
    }
    return this;
  }
}

class AtomPropertyValuePlaceholder extends PropertyValue {
  const AtomPropertyValuePlaceholder(this.value);

  final String value;

  @override
  Object encode() =>
      throw StateError('AtomPropertyValuePlaceholder asked to encode');

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) =>
      throw StateError(
          'AtomPropertyValuePlaceholder asked to encode for server');

  @override
  PropertyValue? resolve(AtomLookupCallback lookupCallback, Atom parent) {
    final Atom? child = lookupCallback(value);
    if (child == null) {
      return null;
    }
    return AtomPropertyValue(child)..registerChildren(parent);
  }

  @override
  PropertyValue deletionNotification(Atom lateAtom) {
    throw StateError(
        'AtomPropertyValuePlaceholder received deletion notification.');
  }
}

class ChildrenPropertyValue extends PropertyValue {
  const ChildrenPropertyValue(this.value);

  final List<PositionedAtom> value;

  @override
  Object encode() => <String, Object>{
        'type': 'child*',
        'children': value
            .map<Map<String, Object?>>((PositionedAtom entry) => entry.encode())
            .toList(),
      };

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) {
    final StringBuffer buffer = StringBuffer();
    for (final PositionedAtom positionedAtom
        in value.where(PositionedAtom.hasChild)) {
      buffer.write('$key: ${positionedAtom.encodeForServerMake(serialized)}; ');
    }
    return buffer.toString();
  }

  @override
  void registerChildren(Atom parent) {
    for (final PositionedAtom positionedAtom in value) {
      positionedAtom.atom?.registerParent(parent);
    }
  }

  @override
  void unregisterChildren(Atom parent) {
    for (final PositionedAtom positionedAtom in value) {
      positionedAtom.atom?.unregisterParent(parent);
    }
  }

  @override
  Iterable<Atom> get children sync* {
    yield* value
        .where((PositionedAtom element) => element.atom != null)
        .map<Atom>((PositionedAtom positionedAtom) => positionedAtom.atom!);
  }

  @override
  PropertyValue deletionNotification(Atom lateAtom) {
    return ChildrenPropertyValue(
      value
          .map<PositionedAtom>(
              (PositionedAtom entry) => entry.deletionNotification(lateAtom))
          .toList(),
    );
  }
}

class ChildrenPropertyValuePlaceholder extends PropertyValue {
  const ChildrenPropertyValuePlaceholder(this.value);

  final List<PositionedAtomPlaceholder> value;

  @override
  Object encode() =>
      throw StateError('ChildrenPropertyValuePlaceholder asked to encode');

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) =>
      throw StateError(
          'ChildrenPropertyValuePlaceholder asked to encode for server');

  @override
  PropertyValue resolve(AtomLookupCallback lookupCallback, Atom parent) {
    return ChildrenPropertyValue(value
        .map<PositionedAtom>(
            (PositionedAtomPlaceholder entry) => entry.resolve(lookupCallback))
        .toList())
      ..registerChildren(parent);
  }

  @override
  PropertyValue deletionNotification(Atom lateAtom) {
    throw StateError(
        'ChildrenPropertyValuePlaceholder received deletion notification.');
  }
}

class PositionedAtom {
  const PositionedAtom(this.position, this.atom);

  final String? position;
  final Atom? atom;

  Map<String, Object?> encode() => <String, Object?>{
        'position': position,
        if (atom != null) 'identifier': atom!.identifier!.identifier,
      };

  String encodeForServerMake(Set<Atom> serialized) {
    return '$position, ${atom!.encodeForServerMake(serialized)}';
  }

  static bool hasChild(PositionedAtom candidate) => candidate.atom != null;

  PositionedAtom deletionNotification(Atom lateAtom) {
    if (atom == lateAtom) {
      return PositionedAtom(position, null);
    }
    return this;
  }
}

class PositionedAtomPlaceholder {
  const PositionedAtomPlaceholder(this.position, this.identifier);

  final String? position;
  final String? identifier;

  PositionedAtom resolve(AtomLookupCallback lookupCallback) {
    return PositionedAtom(position, lookupCallback(identifier!));
  }
}

class LandmarksPropertyValue extends PropertyValue {
  const LandmarksPropertyValue(this.value);

  final List<Landmark> value;

  @override
  Object encode() => <String, Object>{
        'type': 'landmark*',
        'children': value
            .map<Map<String, Object?>>((Landmark entry) => entry.encode())
            .toList(),
      };

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) => '';

  @override
  String encodeForServerConnect(String from) {
    return value.where(Landmark.hasChild).map<String>((Landmark landmark) {
      return 'connect $from, ${landmark.encodeForServerConnect()}';
    }).join('; ');
  }

  @override
  void registerChildren(Atom parent) {
    for (final Landmark landmark in value.where(Landmark.hasChild)) {
      landmark.atom!.registerFriend(parent);
    }
  }

  @override
  void unregisterChildren(Atom parent) {
    for (final Landmark landmark in value.where(Landmark.hasChild)) {
      landmark.atom!.unregisterFriend(parent);
    }
  }

  @override
  Iterable<Atom> get children sync* {
    yield* value
        .where(Landmark.hasChild)
        .map<Atom>((Landmark landmark) => landmark.atom!);
  }

  @override
  PropertyValue deletionNotification(Atom lateAtom) {
    return LandmarksPropertyValue(
      value
          .map<Landmark>(
              (Landmark entry) => entry.deletionNotification(lateAtom))
          .toList(),
    );
  }
}

class LandmarksPropertyValuePlaceholder extends PropertyValue {
  const LandmarksPropertyValuePlaceholder(this.value);

  final List<LandmarkPlaceholder> value;

  @override
  Object encode() =>
      throw StateError('LandmarksPropertyValuePlaceholder asked to encode');

  @override
  String encodeForServerMake(String key, Set<Atom> serialized) =>
      throw StateError(
          'LandmarksPropertyValuePlaceholder asked to encode for server');

  @override
  String encodeForServerConnect(String from) => throw StateError(
      'LandmarksPropertyValuePlaceholder asked to encode for server');

  @override
  PropertyValue resolve(AtomLookupCallback lookupCallback, Atom parent) {
    return LandmarksPropertyValue(value
        .map<Landmark>(
            (LandmarkPlaceholder entry) => entry.resolve(lookupCallback))
        .toList())
      ..registerChildren(parent);
  }

  @override
  PropertyValue deletionNotification(Atom lateAtom) {
    throw StateError(
        'LandmarksPropertyValuePlaceholder received deletion notification.');
  }
}

class Landmark {
  const Landmark(this.direction, this.atom, this.options);

  final String? direction;
  final Atom? atom;
  final Set<String> options;

  Map<String, Object?> encode() => <String, Object?>{
        'direction': direction,
        if (atom != null) 'identifier': atom!.identifier!.identifier,
        'options': options.toList(),
      };

  String encodeForServerConnect() {
    assert(atom !=
        null); // TODO(ianh): we should inform the user that the landmark isn't ready
    return '$direction, ${atom!.identifier!.identifier}, ${options.join(" ")}';
  }

  static bool hasChild(Landmark candidate) => candidate.atom != null;

  Landmark deletionNotification(Atom lateAtom) {
    if (atom == lateAtom) {
      return Landmark(direction, null, options);
    }
    return this;
  }
}

class LandmarkPlaceholder {
  const LandmarkPlaceholder(this.direction, this.identifier, this.options);

  final String? direction;
  final String? identifier;
  final Set<String> options;

  Landmark resolve(AtomLookupCallback lookupCallback) {
    return Landmark(direction,
        identifier != null ? lookupCallback(identifier!) : null, options);
  }
}

class Identifier implements Comparable<Identifier> {
  Identifier(this.name, this.disambiguator);
  factory Identifier.split(String identifier) {
    final int position = identifier.lastIndexOf('_');
    if (position < 0) {
      return Identifier(identifier, 0);
    }
    final int? disambiguator = int.tryParse(identifier.substring(position + 1));
    if (disambiguator == null) {
      return Identifier(identifier, 0);
    }
    return Identifier(identifier.substring(0, position), disambiguator);
  }
  final String name;
  final int disambiguator;
  String get identifier => '${name}_$disambiguator';

  @override
  int compareTo(Identifier other) {
    if (name == other.name) {
      return disambiguator.compareTo(other.disambiguator);
    }
    return name.compareTo(other.name);
  }

  bool matches(String identifier) {
    final Identifier other = Identifier.split(identifier);
    return compareTo(other) == 0;
  }

  @override
  String toString() => identifier;
}

class Atom extends ChangeNotifier implements Comparable<Atom> {
  Atom(this.owner) {
    identifier = owner.getNewIdentifier();
  }

  final AtomOwner owner;

  VoidCallback? get onDead => _onDead;
  VoidCallback? _onDead;
  set onDead(VoidCallback? value) {
    assert(_onDead == null);
    assert(value != null);
    _onDead = value;
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners && onDead != null) {
      onDead!();
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    owner.didChange();
  }

  String get rootClass => 'TAtom';

  Identifier? get identifier => _identifier;
  Identifier? _identifier; // set by constructor
  set identifier(Identifier? value) {
    if (value == _identifier) {
      return;
    }
    _identifier = value;
    notifyListeners();
  }

  String get className => _className;
  String _className = '';
  set className(String value) {
    if (value == _className) {
      return;
    }
    _className = value;
    notifyListeners();
  }

  PropertyValue? operator [](String name) => _properties[name];
  final Map<String, PropertyValue> _properties = <String, PropertyValue>{};
  void operator []=(String name, PropertyValue? value) {
    if (_properties[name] == value) {
      return;
    }
    _properties[name]?.unregisterChildren(this);
    if (value == null) {
      _properties.remove(name);
    } else {
      _properties[name] = value;
    }
    _properties[name]?.registerChildren(this);
    notifyListeners();
  }

  void addAll(Map<String, PropertyValue> properties) {
    for (final String key in properties.keys) {
      _properties[key]?.unregisterChildren(this);
    }
    _properties.addAll(properties);
    for (final String key in properties.keys) {
      _properties[key]?.registerChildren(this);
    }
    notifyListeners();
  }

  T? ensurePropertyIs<T>(String name) {
    if (_properties[name] is T) {
      return _properties[name] as T;
    }
    return null;
  }

  void resolveIdentifiers(AtomLookupCallback lookupCallback) {
    for (final String name in _properties.keys.toList()) {
      final PropertyValue? resolved =
          _properties[name]!.resolve(lookupCallback, this);
      if (resolved == null) {
        _properties.remove(name);
      } else {
        _properties[name] = resolved;
      }
    }
  }

  bool _disconnected = false;

  void disconnect() {
    assert(!_disconnected);
    for (final PropertyValue property in _properties.values) {
      property.unregisterChildren(this);
    }
    _disconnected = true;
  }

  @override
  void dispose() {
    assert(!hasListeners);
    assert(_disconnected);
    super.dispose();
  }

  Map<String, Object?> encode() {
    return <String, Object?>{
      'identifier': identifier!.identifier,
      'className': className,
      for (final String name in _properties.keys)
        '.$name': _properties[name]!.encode(),
    };
  }

  void decode(Map<String, Object?> object) {
    assert(object['identifier'] is String);
    assert(object['className'] is String);
    identifier = Identifier.split(object['identifier'] as String);
    _className = object['className'] as String;
    for (final String property in object.keys) {
      if (property.startsWith('.')) {
        _properties[property.substring(1)] =
            PropertyValue.decode(object[property]);
      }
    }
    notifyListeners();
  }

  String encodeForServerMake(Set<Atom> serialized) {
    if (serialized.contains(this)) {
      return identifier!.identifier;
    }
    serialized.add(this);
    final StringBuffer buffer = StringBuffer();
    for (final String key in _properties.keys) {
      buffer.write(_properties[key]!.encodeForServerMake(key, serialized));
    }
    return 'new $className named ${identifier!.identifier} { $buffer}';
  }

  String encodeForServerConnect() {
    final StringBuffer buffer = StringBuffer();
    for (final String key in _properties.keys) {
      buffer.write(
          _properties[key]!.encodeForServerConnect(identifier!.identifier));
    }
    return buffer.toString();
  }

  Atom? get parent => _parent;
  Atom? _parent;

  Set<Atom> get friends => _friends.keys.toSet();
  final Map<Atom, int> _friends = <Atom, int>{};

  Iterable<Atom> get children =>
      _properties.values.expand<Atom>((PropertyValue value) => value.children);

  int get depth {
    final Atom? parent = this.parent;
    if (parent == null) {
      return 0;
    }
    return parent.depth + 1;
  }

  void registerParent(Atom parent) {
    if (parent != _parent) {
      _parent = parent;
      notifyListeners();
    }
  }

  void unregisterParent(Atom parent) {
    if (parent == _parent) {
      _parent = null;
      notifyListeners();
    }
  }

  void registerFriend(Atom friend) {
    if (_friends.containsKey(friend)) {
      _friends[friend] = _friends[friend]! + 1;
    } else {
      _friends[friend] = 1;
    }
    notifyListeners();
  }

  void unregisterFriend(Atom friend) {
    assert(_friends.containsKey(friend));
    if (_friends[friend]! > 1) {
      _friends[friend] = _friends[friend]! - 1;
    } else {
      assert(_friends[friend] == 1);
      _friends.remove(friend);
    }
    notifyListeners();
  }

  bool canAddToTree(Atom candidateChild) {
    assert(candidateChild.parent != this);
    if (candidateChild.parent != null) {
      return false;
    }
    Atom? ancestor = parent;
    while (ancestor != null) {
      if (ancestor == candidateChild) {
        return false;
      }
      ancestor = ancestor.parent;
    }
    return true;
  }

  void deletionNotification(Atom other) {
    assert(other != this);
    for (final String name in _properties.keys.toList()) {
      final PropertyValue? newValue =
          _properties[name]!.deletionNotification(other);
      if (newValue == null) {
        _properties.remove(name);
      } else {
        _properties[name] = newValue;
      }
    }
  }

  @override
  int compareTo(Atom other) {
    final Atom? parent = this.parent;
    final Atom? otherParent = other.parent;
    if (parent == other) // we are child of other
      return 1;
    if (otherParent == this) // we are parent of other
      return -1;
    if (parent == null &&
        otherParent != null) // same as comparing us to other's parent
      return compareTo(otherParent);
    if (parent != null &&
        otherParent == null) // same as our parent comparing to this
      return parent.compareTo(other);
    if (parent != otherParent) {
      // same as our parent comparing to other's parent (sometimes...)
      assert(parent != null);
      assert(otherParent != null);
      if (depth < other.depth) {
        return compareTo(otherParent!);
      }
      if (depth > other.depth) {
        return parent!.compareTo(other);
      }
      return parent!.compareTo(otherParent!);
    }
    return identifier!.compareTo(
        other.identifier!); // we have same parent (or no parent) as other
  }

  @override
  String toString() => '$identifier';
}
