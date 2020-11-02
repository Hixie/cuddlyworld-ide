import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'atom_widget.dart';
import 'backend.dart';
import 'data_model.dart';
import 'dialogs.dart';
import 'disposition.dart';

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
    widget.game.addListener(_updateProperties);
    widget.atom.addListener(_handleAtomUpdate);
    _updateProperties();
  }

  @override
  void didUpdateWidget(Editor oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool dirty = false;
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateProperties);
      widget.game.addListener(_updateProperties);
      dirty = true;
    }
    if (oldWidget.atom != widget.atom) {
      oldWidget.atom.removeListener(_handleAtomUpdate);
      widget.atom.addListener(_handleAtomUpdate);
      dirty = true;
    }
    if (dirty)
      _updateProperties();
  }

  @override
  void dispose() {
    widget.atom.removeListener(_handleAtomUpdate);
    widget.game.removeListener(_updateProperties);
    super.dispose();
  }

  void _handleAtomUpdate() {
    // TODO(elih): check if Atom.deleted
    setState(() { /* atom changed */ });
    _updateProperties();
  }

  Map<String, String> _properties = const <String, String>{};

  void _updateProperties() async {
    if (widget.atom.className.isEmpty) {
      _properties = const <String, String>{};
      return;
    }
    try {
      final Map<String, String> properties = await widget.game.fetchPropertiesOf(widget.atom.className);
      if (mounted) {
        setState(() {
          _properties = properties;
        });
      }
    } on ConnectionLostException {
      // ignore
    }
  }

  String _prettyName(String property, String type) {
    switch (property) {
      case 'backDescription': return 'Description (back)';
      case 'backSide': return 'Reverse side';
      case 'cannotMoveExcuse': return 'Cannot move excuse';
      case 'child': return type == 'child*' ? 'Children' : 'Child';
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
      case 'landmark': return type == 'landmark*' ? 'Landmarks' : 'Landmark';
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
      case 'atom':
        return AtomField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          rootClass: parts[1],
          value: widget.atom.ensurePropertyIs<AtomPropertyValue>(property)?.value,
          parent: widget.atom,
          needsTree: true,
          needsDifferent: true,
          game: widget.game,
          onChanged: (Atom value) { widget.atom[property] = value != null ? AtomPropertyValue(value) : null; },
        );
      case 'boolean':
        return CheckboxField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          value: widget.atom.ensurePropertyIs<BooleanPropertyValue>(property)?.value,
          onChanged: (bool value) { widget.atom[property] = BooleanPropertyValue(value); },
        );
      case 'child*':
        return ChildrenField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          rootClass: 'TThing',
          values: widget.atom.ensurePropertyIs<ChildrenPropertyValue>(property)?.value ?? const <PositionedAtom>[],
          parent: widget.atom,
          game: widget.game,
          onChanged: (List<PositionedAtom> value) { widget.atom[property] = ChildrenPropertyValue(value); },
        );
      case 'class':
        return ClassesField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          rootClass: parts[1],
          value: widget.atom.ensurePropertyIs<LiteralPropertyValue>(property)?.value ?? '',
          game: widget.game,
          onChanged: (String value) { widget.atom[property] = LiteralPropertyValue(value); },
        );
      case 'enum':
        return EnumField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          enumName: parts[1],
          value: widget.atom.ensurePropertyIs<LiteralPropertyValue>(property)?.value ?? '',
          game: widget.game,
          onChanged: (String value) { widget.atom[property] = LiteralPropertyValue(value); },
        );
      case 'landmark*':
        return LandmarksField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          rootClass: 'TAtom',
          values: widget.atom.ensurePropertyIs<LandmarksPropertyValue>(property)?.value ?? const <Landmark>[],
          parent: widget.atom,
          game: widget.game,
          onChanged: (List<Landmark> value) { widget.atom[property] = LandmarksPropertyValue(value); },
        );
      case 'string':
        return StringField(
          key: ValueKey<String>(property),
          label: _prettyName(property, propertyType),
          value: widget.atom.ensurePropertyIs<StringPropertyValue>(property)?.value ?? '',
          onChanged: (String value) { widget.atom[property] = StringPropertyValue(value); },
        );
      default:
        return StringField(
          key: ValueKey<String>(property),
          label: '${_prettyName(property, propertyType)} ($propertyType)',
          value: widget.atom.ensurePropertyIs<StringPropertyValue>(property)?.value ?? '',
          onChanged: (String value) { widget.atom[property] = StringPropertyValue(value); },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Atom parent = widget.atom.parents.length == 1 ? widget.atom.parents.single : null;
    return SizedBox.expand(
      child: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            if (parent != null)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () { EditorDisposition.of(context).current = parent; },
                  icon: const Icon(Icons.arrow_upward),
                  label: makeTextForIdentifier(context, parent.identifier, parent.className),
                ),
              ),
            StringField(
              label: 'Identifier',
              value: widget.atom.identifier.name,
              suffix: '_${widget.atom.identifier.disambiguator}',
              filter: '[0-9A-Za-z_]+',
              onChanged: (String value) { widget.atom.identifier = RootDisposition.of(context).getNewIdentifier(name: value, ignore: widget.atom); },
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
            Padding(
              padding: const EdgeInsets.all(48.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () {
                      EditorDisposition.of(context).current = null;
                      AtomsDisposition.of(context).remove(widget.atom);
                    },
                    child: const Text('Delete'),
                  ),
                  const SizedBox(width: 24.0),
                  OutlinedButton(
                    onPressed: () async {
                      final String heading = 'Adding ${widget.atom.identifier.identifier} to world';
                      try {
                        final String reply = await widget.game.sendMessage(
                          'debug make \'${escapeSingleQuotes(widget.atom.encodeForServer(<Atom>{}))}\'',
                        );
                        await showMessage(context, heading, reply);
                      } on ConnectionLostException {
                        await showMessage(context, heading, 'Conection lost');
                      }
                    },
                    child: const Text('Add to world'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _makeField(String label, FocusNode focusNode, Widget field) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 200.0,
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

Widget _makeDropdown(List<String> values, String value, FocusNode focusNode, ValueSetter<String> onChanged) {
  if (values.isEmpty)
    return const Text('Loading...', style: TextStyle(fontStyle: FontStyle.italic));
  return DropdownButton<String>(
    items: values.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    )).toList(),
    value: values.contains(value) ? value : null,
    focusNode: focusNode,
    onChanged: onChanged,
  );
}

Widget _pad(Widget child) => Padding(
  padding: const EdgeInsets.all(8.0),
  child: child,
);

Widget _makeAtomSlot(Set<String> classes, Atom value, Atom parent, ValueSetter<Atom> onChanged, {
  @required bool needsTree,
  @required bool needsDifferent,
}) {
  assert(parent != null);
  bool _ok(Atom atom) => (!needsTree || parent.canAddToTree(atom))
                      && (!needsDifferent || parent != atom);
  return DragTarget<Atom>(
    onWillAccept: (Atom atom) => classes.contains(atom.className) && _ok(atom),
    onAccept: (Atom atom) {
      if (_ok(atom))
        onChanged(atom);
    },
    builder: (BuildContext context, List<Atom> candidateData, List<Object> rejectedData) {
      return Material(
        color: const Color(0x0A000000),
        child: Wrap(
          children: <Widget>[
            if (value != null && candidateData.isEmpty)
              _pad(AtomWidget(
                atom: value,
                onDelete: () { onChanged(null); },
                onTap: () { EditorDisposition.of(context).current = value; },
              )),
            ...candidateData.map<Widget>((Atom atom) => _pad(AtomWidget(atom: atom))),
            ...rejectedData.whereType<Atom>().map<Widget>((Atom atom) => _pad(AtomWidget(atom: atom, color: Colors.red))),
            if (value == null && candidateData.isEmpty && rejectedData.isEmpty)
              _pad(AtomWidget(
                elevation: 0.0,
                label: const SizedBox(width: 64.0, child: Text('')),
                color: const Color(0xFFE0E0E0),
                onTap: (classes.isEmpty) ? null : () {
                  final Atom newAtom = AtomsDisposition.of(context).add()
                    ..className = classes.first;
                  onChanged(newAtom);
                  EditorDisposition.of(context).current = newAtom;
                },
              )),
          ],
        ),
      );
    },
  );
}

class StringField extends StatefulWidget {
  const StringField({
    Key key,
    @required this.label,
    @required this.value,
    this.suffix,
    this.filter,
    this.onChanged,
  }): super(key: key);

  final String label;
  final String value;
  final String suffix;
  final String filter;
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
    return _makeField(widget.label, _focusNode, Expanded(
      child: TextField(
        focusNode: _focusNode,
        controller: _controller,
        decoration: InputDecoration(
          filled: true,
          border: InputBorder.none,
          suffix: widget.suffix != null ? Text(widget.suffix) : null,
        ),
        inputFormatters: <TextInputFormatter>[ if (widget.filter != null) FilteringTextInputFormatter.allow(RegExp(widget.filter)) ],
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

  List<String> _classes = const <String>[];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _updateClasses();
    widget.game.addListener(_updateClasses);
  }

  void _updateClasses() async {
    try {
      final List<String> result = await widget.game.fetchClassesOf(widget.rootClass);
      if (!mounted)
        return;
      setState(() { _classes = result..sort(); });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(ClassesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateClasses);
      widget.game.addListener(_updateClasses);
      _updateClasses();
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
    return _makeField(widget.label, _focusNode, _makeDropdown(_classes, widget.value, _focusNode, widget.onChanged));
  }
}

class EnumField extends StatefulWidget {
  const EnumField({
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
  State<EnumField> createState() => _EnumFieldState();
}

class _EnumFieldState extends State<EnumField> {
  FocusNode _focusNode;

  List<String> _enumValues = const <String>[];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _updateEnumValues();
    widget.game.addListener(_updateEnumValues);
  }

  void _updateEnumValues() async {
    try {
      final List<String> result = await widget.game.fetchEnumValuesOf(widget.enumName);
      if (!mounted)
        return;
      setState(() { _enumValues = result; });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(EnumField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateEnumValues);
      widget.game.addListener(_updateEnumValues);
      _updateEnumValues();
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
    return _makeField(widget.label, _focusNode, _makeDropdown(_enumValues, widget.value, _focusNode, widget.onChanged));
  }
}

class CheckboxField extends StatefulWidget {
  const CheckboxField({
    Key key,
    @required this.label,
    @required this.value,
    this.onChanged,
  }): super(key: key);

  final String label;
  final bool value;
  final ValueSetter<bool> onChanged;

  @override
  State<CheckboxField> createState() => _CheckboxFieldState();
}

class _CheckboxFieldState extends State<CheckboxField> {
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _makeField(widget.label, _focusNode, Checkbox(
      value: widget.value,
      tristate: widget.value == null,
      onChanged: (bool value) => widget.onChanged(value),
    ));
  }
}

class AtomField extends StatefulWidget {
  const AtomField({
    Key key,
    @required this.game,
    @required this.rootClass,
    @required this.label,
    @required this.value,
    @required this.parent,
    this.needsTree = false,
    this.needsDifferent = false,
    this.onChanged,
  }): super(key: key);

  final CuddlyWorld game;
  final String rootClass;
  final String label;
  final Atom value;
  final Atom parent;
  final bool needsTree;
  final bool needsDifferent;
  final ValueSetter<Atom> onChanged;

  @override
  State<AtomField> createState() => _AtomFieldState();
}

class _AtomFieldState extends State<AtomField> {
  FocusNode _focusNode;

  Set<String> _classes = const <String>{};

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _updateClasses();
    widget.game.addListener(_updateClasses);
  }

  void _updateClasses() async {
    try {
      final List<String> result = await widget.game.fetchClassesOf(widget.rootClass);
      if (!mounted)
        return;
      setState(() { _classes = result.toSet(); });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(AtomField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_updateClasses);
      widget.game.addListener(_updateClasses);
      _updateClasses();
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
    return _makeField(widget.label, _focusNode, Expanded(
      child: _makeAtomSlot(
        _classes,
        widget.value,
        widget.parent,
        widget.onChanged,
        needsTree: widget.needsTree,
        needsDifferent: widget.needsDifferent,
      ),
    ));
  }
}

class ChildrenField extends StatefulWidget {
  const ChildrenField({
    Key key,
    @required this.game,
    @required this.rootClass,
    @required this.label,
    @required this.values,
    @required this.parent,
    this.onChanged,
  }): super(key: key);

  final CuddlyWorld game;
  final String rootClass;
  final String label;
  final List<PositionedAtom> values;
  final Atom parent;
  final ValueSetter<List<PositionedAtom>> onChanged;

  @override
  State<ChildrenField> createState() => _ChildrenFieldState();
}

class _ChildrenFieldState extends State<ChildrenField> {
  Set<String> _classes = const <String>{};
  List<String> _thingPositionValues = const <String>[];

  @override
  void initState() {
    super.initState();
    _triggerUpdates();
    widget.game.addListener(_triggerUpdates);
  }

  void _triggerUpdates() {
    _updateClasses();
    _updateThingPositionValues();
  }

  void _updateClasses() async {
    try {
      final List<String> result = await widget.game.fetchClassesOf(widget.rootClass);
      if (!mounted)
        return;
      setState(() { _classes = result.toSet(); });
    } on ConnectionLostException {
      // ignore
    }
  }

  void _updateThingPositionValues() async {
    try {
      final List<String> result = await widget.game.fetchEnumValuesOf('TThingPosition');
      if (!mounted)
        return;
      setState(() { _thingPositionValues = result; });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(ChildrenField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_triggerUpdates);
      widget.game.addListener(_triggerUpdates);
      _triggerUpdates();
    } else if (oldWidget.rootClass != widget.rootClass) {
      _updateClasses();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_triggerUpdates);
    super.dispose();
  }

  Widget _row(String position, Atom atom, Function(String position, Atom atom) onChanged, VoidCallback onDelete) {
    return Row(
      children: <Widget>[
        _makeDropdown(_thingPositionValues, position, null, (String position) { onChanged(position, atom); }),
        const SizedBox(
          width: 8.0,
        ),
        Expanded(
          child: _makeAtomSlot(_classes, atom, widget.parent, (Atom atom) { onChanged(position, atom); }, needsTree: true, needsDifferent: true),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: onDelete,
          ),
      ],
    );
  }
                
  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < widget.values.length; index += 1) {
      final PositionedAtom entry = widget.values[index];
      rows.add(_row(
        entry.position,
        entry.atom,
        (String position, Atom atom) {
          final List<PositionedAtom> newValues = widget.values.toList();
          newValues[index] = PositionedAtom(position, atom);
          widget.onChanged(newValues);
        },
        () {
          final List<PositionedAtom> newValues = widget.values.toList()
            ..removeAt(index);
          widget.onChanged(newValues);
        },
      ));
    }
    rows.add(_row(
      '',
      null,
      (String position, Atom atom) {
        final List<PositionedAtom> newValues = widget.values.toList()
          ..add(PositionedAtom(position, atom));
        widget.onChanged(newValues);
      },
      null,
    ));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 200.0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('${widget.label}:', textAlign: TextAlign.right),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(
            child: ListBody(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}

class LandmarksField extends StatefulWidget {
  const LandmarksField({
    Key key,
    @required this.game,
    @required this.rootClass,
    @required this.label,
    @required this.values,
    @required this.parent,
    this.onChanged,
  }): super(key: key);

  final CuddlyWorld game;
  final String rootClass;
  final String label;
  final List<Landmark> values;
  final Atom parent;
  final ValueSetter<List<Landmark>> onChanged;

  @override
  State<LandmarksField> createState() => _LandmarksFieldState();
}

class _LandmarksFieldState extends State<LandmarksField> {
  Set<String> _classes = const <String>{};
  List<String> _cardinalDirectionValues = const <String>[];
  List<String> _landmarkOptionValues = const <String>[];

  @override
  void initState() {
    super.initState();
    _triggerUpdates();
    widget.game.addListener(_triggerUpdates);
  }

  void _triggerUpdates() {
    _updateClasses();
    _updateThingPositionValues();
    _updateLandmarkOptionValues();
  }

  void _updateClasses() async {
    try {
      final List<String> result = await widget.game.fetchClassesOf(widget.rootClass);
      if (!mounted)
        return;
      setState(() { _classes = result.toSet(); });
    } on ConnectionLostException {
      // ignore
    }
  }

  void _updateThingPositionValues() async {
    try {
      final List<String> result = await widget.game.fetchEnumValuesOf('TCardinalDirection');
      if (!mounted)
        return;
      setState(() { _cardinalDirectionValues = result; });
    } on ConnectionLostException {
      // ignore
    }
  }

  void _updateLandmarkOptionValues() async {
    try {
      final List<String> result = await widget.game.fetchEnumValuesOf('TLandmarkOption');
      if (!mounted)
        return;
      setState(() { _landmarkOptionValues = result; });
    } on ConnectionLostException {
      // ignore
    }
  }

  @override
  void didUpdateWidget(LandmarksField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_triggerUpdates);
      widget.game.addListener(_triggerUpdates);
      _triggerUpdates();
    } else if (oldWidget.rootClass != widget.rootClass) {
      _updateClasses();
    }
  }

  @override
  void dispose() {
    widget.game.removeListener(_triggerUpdates);
    super.dispose();
  }

  Widget _row(String direction, Atom atom, Set<String> options, Function(String direction, Atom atom, Set<String> options) onChanged, VoidCallback onDelete) {
    return ListBody(
      children: <Widget>[
        Row(
          children: <Widget>[
            _makeDropdown(_cardinalDirectionValues, direction, null, (String direction) { onChanged(direction, atom, options); }),
            const SizedBox(
              width: 8.0,
            ),
            Expanded(
              child: _makeAtomSlot(_classes, atom, widget.parent, (Atom atom) { onChanged(direction, atom, options); }, needsTree: false, needsDifferent: true),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: onDelete,
              ),
          ],
        ),
        Wrap(
          children: <Widget>[
            for (final String option in _landmarkOptionValues)
              _pad(
                FilterChip(
                  label: Text(option),
                  selected: options.contains(option),
                  onSelected: (bool selected) {
                    if (selected)
                      onChanged(direction, atom, options.toSet()..add(option));
                    else
                      onChanged(direction, atom, options.toSet()..remove(option));
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }
                
  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < widget.values.length; index += 1) {
      final Landmark entry = widget.values[index];
      rows.add(_row(
        entry.direction,
        entry.atom,
        entry.options,
        (String direction, Atom atom, Set<String> options) {
          final List<Landmark> newValues = widget.values.toList();
          newValues[index] = Landmark(direction, atom, options);
          widget.onChanged(newValues);
        },
        () {
          final List<Landmark> newValues = widget.values.toList()
            ..removeAt(index);
          widget.onChanged(newValues);
        },
      ));
    }
    rows.add(_row(
      '',
      null,
      <String>{},
      (String direction, Atom atom, Set<String> options) {
        final List<Landmark> newValues = widget.values.toList()
          ..add(Landmark(direction, atom, options));
        widget.onChanged(newValues);
      },
      null,
    ));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 200.0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('${widget.label}:', textAlign: TextAlign.right),
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Expanded(
            child: ListBody(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}
