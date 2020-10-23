import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'catalog.dart';
import 'data_model.dart';
import 'disposition.dart';

class AtomWidget extends StatefulWidget {
  const AtomWidget({
    Key key,
    this.label,
    this.atom,
    this.color,
    this.elevation = 3.0,
    this.startFromCatalog = false,
    this.curve = Curves.easeInQuint,
    this.duration = const Duration(milliseconds: 200),
    this.onDelete,
  }): assert((label == null) != (atom == null)),
      super(key: key);

  final Atom atom;
  final Widget label;
  final Color color;
  final double elevation;
  final bool startFromCatalog;
  final Curve curve;
  final Duration duration;
  final VoidCallback onDelete;

  @override
  State<AtomWidget> createState() => _AtomWidgetState();
}

class _AtomWidgetState extends State<AtomWidget> with SingleTickerProviderStateMixin {
  Timer _timer;
  bool _chip = true;

  @override
  void initState() {
    super.initState();
    if (widget.startFromCatalog) {
      _chip = false;
      _timer = Timer(const Duration(milliseconds: 50), () { setState(() { _chip = true; }); });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: _chip ? widget.elevation : 0.0,
      color: widget.color ?? (widget.atom != null && widget.atom == EditorDisposition.of(context).current ? Colors.yellow : null),
      shape: _chip ? const StadiumBorder() : const RoundedRectangleBorder(),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        alignment: Alignment.centerLeft,
        curve: widget.curve,
        duration: widget.duration,
        vsync: this,
        child: SizedBox(
          width: _chip ? null : kCatalogWidth,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0, right: widget.onDelete != null ? 4.0 : 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                widget.label ?? Text(
                  widget.atom.name.value.isEmpty ? '<unnamed>' : widget.atom.name.value,
                  style: widget.atom.name.value.isEmpty ? const TextStyle(fontStyle: FontStyle.italic) : null,
                ),
                if (widget.onDelete != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkResponse(
                      onTap: widget.onDelete,
                      radius: 18.0,
                      child: const Icon(Icons.cancel, size: 18.0),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
