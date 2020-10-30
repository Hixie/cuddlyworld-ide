import 'package:flutter/material.dart';

import 'atom_widget.dart';
import 'data_model.dart';
import 'disposition.dart';

const double kCatalogWidth = 350.0;

class Catalog extends StatefulWidget {
  const Catalog({Key key}) : super(key: key);
  @override
  _CatalogState createState() => _CatalogState();
}

class _CatalogState extends State<Catalog> with SingleTickerProviderStateMixin {
  List<Atom> _atoms = <Atom>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final Atom element in _atoms) {
      element.removeListener(_handleListUpdate);
    }
    _atoms = AtomsDisposition.of(context).atoms.toList();
    _handleListUpdate();
    for (final Atom element in _atoms) {
      element.addListener(_handleListUpdate);
    }
  }

  void _handleListUpdate() {
    setState(() {
      _atoms.sort();
    });
  }

  @override
  void dispose() {
    for (final Atom element in _atoms) {
      element.removeListener(_handleListUpdate);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 36.0),
        child: FocusTraversalGroup(
          child: ListView(
            children: _atoms.map<Widget>((Atom e) => DraggableText(atom: e)).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          EditorDisposition.of(context).current = AtomsDisposition.of(context).add();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DraggableText extends StatefulWidget {
  const DraggableText({this.atom, Key key}): super(key: key);

  final Atom atom;

  @override
  _DraggableTextState createState() => _DraggableTextState();
}

class _DraggableTextState extends State<DraggableText> {
  @override
  Widget build(BuildContext context) {
    return Draggable<Atom>(
      data: widget.atom,
      dragAnchor: DragAnchor.pointer,
      feedback: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Material(
          type: MaterialType.transparency,
          child: AtomWidget(
            atom: widget.atom,
            startFromCatalog: true,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: widget.atom.parent != null ? 0.0 : 8.0),
        child: FlatButton(
          color: widget.atom == EditorDisposition.of(context).current ? Colors.yellow : null,
          onPressed: () {
            setState(() {
              EditorDisposition.of(context).current = widget.atom;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0 * widget.atom.depth,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: makeTextForIdentifier(context, widget.atom.identifier, widget.atom.className),
            ),
          ),
        ),
      ),
    );
  }
}
