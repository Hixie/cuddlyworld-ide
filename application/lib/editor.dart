import 'package:flutter/material.dart';

import 'backend.dart';
import 'data_model.dart';

class Editor extends StatefulWidget {
  const Editor({ Key key, this.game, this.atom }): super(key: key);

  final CuddlyWorld game;

  final Atom atom;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  @override
  void initState() {
    super.initState();
    widget.atom.addListener(_handleAtomUpdate);
    _updateProperties();
  }

  @override
  void didUpdateWidget(Editor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atom != widget.atom) {
      oldWidget.atom.removeListener(_handleAtomUpdate);
      widget.atom.addListener(_handleAtomUpdate);
      _updateProperties();
    }
  }

  @override
  void dispose() {
    widget.atom.removeListener(_handleAtomUpdate);
    super.dispose();
  }

  void _handleAtomUpdate() {
    setState(() { /* atom changed */ });
    _updateProperties();
  }

  Map<String, String> _properties = const <String, String>{};

  void _updateProperties() async {
    if (widget.atom.className.isEmpty) {
      _properties = const <String, String>{};
      return;
    }
    final Map<String, String> properties = await widget.game.fetchPropertiesOf(widget.atom.className);
    if (mounted) {
      setState(() {
        _properties = properties;
      });
    }
  }

  String _prettyName(String property) {
    switch (property) {
      case 'backDescription': return 'Description (back)';
      case 'backSide': return 'Reverse side';
      case 'cannotMoveExcuse': return 'Cannot move excuse';
      case 'child': return 'Children';
      case 'definiteName': return 'Name (definite)';
      case 'description': return 'Description';
      case 'destination': return 'Destination';
      case 'door': return 'Door';
      case 'findDescription': return 'Description (find)';
      case 'frontDirection': return 'Direction of front';
      case 'frontDescription': return 'Description (front)';
      case 'frontSide': return 'Front side';
      case 'ground': return 'Ground';
      case 'indefiniteName': return 'Name (indefinite)';
      case 'ingredients': return 'Ingredients';
      case 'mass': return 'Mass';
      case 'master': return 'Master';
      case 'maxSize': return 'Maximum size';
      case 'name': return 'Name';
      case 'landmark': return 'Landmarks';
      case 'opened': return 'Opened?';
      case 'pattern': return 'Pattern';
      case 'pileClass': return 'Pile class';
      case 'position': return 'Position';
      case 'size': return 'Size';
      case 'surface': return 'Surface';
      case 'underDescription': return 'Description (under)';
      case 'writing': return 'Writing';
      default: return property;
    }
  }

  Widget _addField(String property, String propertyType) {
    final List<String> parts = propertyType.split(':');
    assert(parts.isNotEmpty);
    assert(parts.length <= 2);
    switch (parts[0]) {
      case 'class':
        return ClassesField(
          key: ValueKey<String>(property),
          label: _prettyName(property),
          rootClass: parts[1],
          value: widget.atom[property],
          game: widget.game,
          onChanged: (String value) { widget.atom[property] = value; },
        );
      case 'string':
        return StringField(
          key: ValueKey<String>(property),
          label: _prettyName(property),
          value: widget.atom[property],
          onChanged: (String value) { widget.atom[property] = value; },
        );
      case 'enum':
        return DropdownField(
          key: ValueKey<String>(property),
          label: _prettyName(property),
          enumName: parts[1],
          value: widget.atom[property],
          game: widget.game,
          onChanged: (String value) { widget.atom[property] = value; },
        );
      default:
        return StringField(
          key: ValueKey<String>(property),
          label: '${_prettyName(property)} ($propertyType)',
          value: widget.atom[property],
          onChanged: (String value) { widget.atom[property] = value; },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(widget.atom.kindDescription, style: Theme.of(context).textTheme.headline4),
            StringField(
              label: 'Identifier',
              value: widget.atom.name.value,
              onChanged: (String value) { widget.atom.name.value = value; },
            ),
            ClassesField(
              label: 'Class',
              rootClass: widget.atom.rootClass,
              value: widget.atom.className,
              game: widget.game,
              onChanged: (String value) { widget.atom.className = value; },
            ),
            for (final String property in _properties.keys)
              _addField(property, _properties[property]),
          ],
        ),
      ),
    );
  }
}

Widget _makeEditor(String label, FocusNode focusNode, Widget field) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 120.0,
            child: InkWell(
              onTap: () {
                focusNode.requestFocus();
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('$label:', textAlign: TextAlign.right),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          field,
        ],
      ),
    ),
  );
}

class StringField extends StatefulWidget {
  const StringField({
    Key key,
    @required this.label,
    @required this.value,
    this.onChanged,
  }): super(key: key);

  final String label;
  final String value;
  final ValueSetter<String> onChanged;

  @override
  State<StringField> createState() => _StringFieldState();
}

class _StringFieldState extends State<StringField> {
  TextEditingController _controller;
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(StringField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeEditor(widget.label, _focusNode, Expanded(
      child: TextField(
        focusNode: _focusNode,
        controller: _controller,
        decoration: const InputDecoration(
          filled: true,
          border: InputBorder.none,
        ),
        onChanged: widget.onChanged,
      ),
    ));
  }
}

class ClassesField extends StatefulWidget {
  const ClassesField({
    Key key,
    @required this.game,
    @required this.rootClass,
    @required this.label,
    @required this.value,
    this.onChanged,
  }): super(key: key);

  final CuddlyWorld game;
  final String rootClass;
  final String label;
  final String value;
  final ValueSetter<String> onChanged;

  @override
  State<ClassesField> createState() => _ClassesFieldState();
}

class _ClassesFieldState extends State<ClassesField> {
  FocusNode _focusNode;

  List<String> _classes = <String>[];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _updateClasses();
    widget.game.addListener(_updateClasses);
  }

  void _updateClasses() async {
    final List<String> result = await widget.game.fetchClassesOf(widget.rootClass);
    if (!mounted)
      return;
    setState(() { _classes = result..sort(); });
  }

  @override
  void didUpdateWidget(ClassesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateClasses);
      widget.game.addListener(_updateClasses);
    } else if (oldWidget.rootClass != widget.rootClass) {
      _updateClasses();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_updateClasses);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeEditor(widget.label, _focusNode, DropdownButton<String>(
      items: _classes.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      )).toList(),
      value: _classes.contains(widget.value) ? widget.value : null,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
    ));
  }
}

class DropdownField extends StatefulWidget {
  const DropdownField({
    Key key,
    @required this.game,
    @required this.enumName,
    @required this.label,
    @required this.value,
    this.onChanged,
  }): super(key: key);

  final CuddlyWorld game;
  final String enumName;
  final String label;
  final String value;
  final ValueSetter<String> onChanged;

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  FocusNode _focusNode;

  List<String> _enumValues = <String>[];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _updateEnumValues();
    widget.game.addListener(_updateEnumValues);
  }

  void _updateEnumValues() async {
    final List<String> result = await widget.game.fetchEnumValuesOf(widget.enumName);
    if (!mounted)
      return;
    setState(() { _enumValues = result..sort(); });
  }

  @override
  void didUpdateWidget(DropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateEnumValues);
      widget.game.addListener(_updateEnumValues);
    } else if (oldWidget.enumName != widget.enumName) {
      _updateEnumValues();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_updateEnumValues);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeEditor(widget.label, _focusNode, DropdownButton<String>(
      items: _enumValues.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      )).toList(),
      value: _enumValues.contains(widget.value) ? widget.value : null,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
    ));
  }
}