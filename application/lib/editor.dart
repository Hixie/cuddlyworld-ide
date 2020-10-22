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

  Widget _addField(String property, String propertyType) {
    switch (propertyType) {
      case 'class:TThing':
        return ClassesField(
          key: ValueKey<String>(property),
          label: property,
          kind: 'things',
          value: widget.atom[property],
          game: widget.game,
          onChanged: (String value) { widget.atom[property] = value; },
        );
      case 'class:TLocation':
        return ClassesField(
          key: ValueKey<String>(property),
          label: property,
          kind: 'things',
          value: widget.atom[property],
          game: widget.game,
          onChanged: (String value) { widget.atom[property] = value; },
        );
      case 'string':
        return StringField(
          key: ValueKey<String>(property),
          label: property,
          value: widget.atom[property],
          onChanged: (String value) { widget.atom[property] = value; },
        );
      default:
        return StringField(
          key: ValueKey<String>(property),
          label: '$property ($propertyType)',
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
              label: 'Name',
              value: widget.atom.name.value,
              onChanged: (String value) { widget.atom.name.value = value; },
            ),
            ClassesField(
              label: 'Class',
              kind: widget.atom.kindCode,
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 120.0,
            child: InkWell(
              onTap: () {
                _focusNode.requestFocus();
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${widget.label}:'),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              decoration: const InputDecoration(
                filled: true,
                border: InputBorder.none,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class ClassesField extends StatefulWidget {
  const ClassesField({
    Key key,
    @required this.game,
    @required this.kind,
    @required this.label,
    @required this.value,
    this.onChanged,
  }): super(key: key);

  final CuddlyWorld game;
  final String kind;
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
    final List<String> result = await widget.game.fetchClassesOf(widget.kind);
    if (!mounted)
      return;
    setState(() { _classes = result; });
  }

  @override
  void didUpdateWidget(ClassesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateClasses);
      widget.game.addListener(_updateClasses);
    } else if (oldWidget.kind != widget.kind) {
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 120.0,
            child: InkWell(
              onTap: () {
                _focusNode.requestFocus();
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${widget.label}:'),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          DropdownButton<String>(
            items: _classes.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            )).toList(),
            value: _classes.contains(widget.value) ? widget.value : null,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}
