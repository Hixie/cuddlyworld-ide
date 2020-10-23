import 'package:flutter/material.dart';

import 'data_model.dart';
import 'disposition.dart';

const double kCatalogWidth = 350.0;

class AtomWidget extends StatelessWidget {
  const AtomWidget({
    Key key,
    this.label,
    this.atom,
    this.color,
    this.elevation = 3.0,
    this.onDelete,
  }): assert((label == null) != (atom == null)),
      super(key: key);

  final Atom atom;
  final Widget label;
  final Color color;
  final double elevation;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Chip(
      elevation: elevation,
      backgroundColor: color ?? (atom != null && atom == EditorDisposition.of(context).current ? Colors.yellow : Colors.white),
      onDeleted: onDelete,
      label: label ?? Text(
        atom.name.value.isEmpty ? '<unnamed>' : atom.name.value,
        style: atom.name.value.isEmpty ? const TextStyle(fontStyle: FontStyle.italic) : null,
      ),
    );
  }
}
