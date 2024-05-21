import 'data_model.dart';

Map<String, PropertyValue?> updateFields(
    Atom atom,
    String property,
    PropertyValue? oldValue,
    PropertyValue? newValue,
    Map<String, String> properties) {
  final Map<String, PropertyValue> result = <String, PropertyValue>{};
  if (property == 'name' &&
      oldValue is StringPropertyValue &&
      newValue is StringPropertyValue) {
    _considerSubstitution(result, atom, 'definiteName', properties,
        oldValue.value.trim(), newValue.value.trim(),
        prefixes: <String>{'the '},
        newPrefix: 'the ',
        setIfEmpty: true,
        trim: true);
    _considerSubstitution(result, atom, 'indefiniteName', properties,
        oldValue.value.trim(), newValue.value.trim(),
        prefixes: <String>{'a ', 'an '},
        newPrefix: '${_an(newValue.value)} ',
        setIfEmpty: true,
        trim: true);
    _considerSubstitution(result, atom, 'description', properties,
        'The ${oldValue.value.trim()} ', 'The ${newValue.value.trim()} ',
        prefixOnly: true);
  }
  return result;
}

final RegExp _startWordBoundary = RegExp(r'^\b');
final RegExp _endWordBoundary = RegExp(r'.*\b$');
final RegExp _whitespace = RegExp('[ \t\r\n]+');

bool _considerSubstitution(
  Map<String, PropertyValue> result,
  Atom atom,
  String property,
  Map<String, String> properties,
  String pattern,
  String replacement, {
  bool prefixOnly = false,
  bool setIfEmpty = false,
  Set<String> prefixes = const <String>{},
  String? newPrefix,
  bool trim = false,
}) {
  if (properties[property] != 'string') {
    return false;
  }
  final StringPropertyValue? current =
      atom.ensurePropertyIs<StringPropertyValue>(property);
  if (current == null || current.value.isEmpty) {
    if (setIfEmpty) {
      assert(newPrefix != null);
      result[property] = StringPropertyValue('$newPrefix$replacement');
      return true;
    }
    return false;
  }
  final RegExp fullPattern;
  if (pattern.isEmpty) {
    fullPattern = RegExp(
        r'(?:^|(?<= ))$'); // i.e. end of pattern but only if there's a trailing space or if the string is empty (ignoring prefixes)
  } else {
    final bool startsWithWord =
        _startWordBoundary.matchAsPrefix(pattern) != null;
    final bool endsWithWord = _endWordBoundary.matchAsPrefix(pattern) != null;
    fullPattern = RegExp('${prefixOnly ? "^" : ""}'
        '${startsWithWord ? r"\b" : ""}'
        '${RegExp.escape(trim ? pattern.replaceAll(_whitespace, ' ') : pattern)}'
        '${endsWithWord ? r"\b" : ""}');
  }
  int skipLength = 0;
  for (final String prefix in prefixes) {
    if (current.value.startsWith(prefix)) {
      skipLength = prefix.length;
      break;
    }
  }
  final String prefix = current.value.substring(0, skipLength);
  final String target = current.value.substring(skipLength);
  if (target.contains(fullPattern)) {
    String fullNewValue =
        '${newPrefix ?? prefix}${target.replaceAll(fullPattern, replacement)}';
    if (trim) {
      fullNewValue = fullNewValue.replaceAll(_whitespace, ' ');
    }
    result[property] = StringPropertyValue(fullNewValue);
    return true;
  }
  return false;
}

String _an(String word) {
  if (word.startsWith('a') ||
      word.startsWith('e') ||
      word.startsWith('h') ||
      word.startsWith('i') ||
      word.startsWith('o') ||
      word.startsWith('u') ||
      word.startsWith('y')) {
    return 'an';
  }
  return 'a';
}
