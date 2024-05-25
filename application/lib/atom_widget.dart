import 'dart:async';

import 'package:flutter/material.dart';

import 'catalog.dart';
import 'data_model.dart';
import 'disposition.dart';

Color _fade(Color color) {
  final HSVColor hsv = HSVColor.fromColor(color);
  return hsv.withValue((hsv.value + 0.5) % 1).toColor();
}

Widget makeTextForIdentifier(BuildContext context, Identifier identifier,
    [String className = '']) {
  return Text.rich(
    TextSpan(
      text: identifier.name,
      children: <InlineSpan>[
        if (identifier.disambiguator > 0)
          TextSpan(
            text: '_${identifier.disambiguator}',
            style: TextStyle(
              color: _fade(DefaultTextStyle.of(context).style.color!),
            ),
          ),
        if (className.isNotEmpty)
          TextSpan(
            text: ' ($className)',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    ),
  );
}

class AtomWidget extends StatefulWidget {
  AtomWidget({
    this.atom,
    this.icon,
    this.label,
    this.color,
    this.elevation = 3.0,
    this.startFromCatalog = false,
    this.curve = Curves.easeInQuint,
    this.duration = const Duration(milliseconds: 200),
    this.onDelete,
    this.onTap,
  })  : assert((label == null) != (atom == null)),
        super(key: atom != null ? ValueKey<Atom>(atom) : null);

  final Atom? atom;
  final Widget? icon;
  final Widget? label;
  final Color? color;
  final double elevation;
  final bool startFromCatalog;
  final Curve curve;
  final Duration duration;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  State<AtomWidget> createState() => _AtomWidgetState();
}

class _AtomWidgetState extends State<AtomWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _chip = true;

  @override
  void initState() {
    super.initState();
    updateWarnings();
    widget.atom?.addListener(updateWarnings);
    if (widget.startFromCatalog) {
      _chip = false;
      _timer = Timer(const Duration(milliseconds: 50), () {
        setState(() {
          _chip = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool atomlessLandmark = false;
  bool directionlessLandmark = false;
  bool duplicateLandmark = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: _chip ? widget.elevation : 0.0,
      color: widget.color ??
          (widget.atom != null &&
                  widget.atom == EditorDisposition.of(context).current
              ? RootDisposition.of(context).darkMode
                  ? Colors.purple
                  : Colors.yellow
              : null),
      shape: _chip ? const StadiumBorder() : const RoundedRectangleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedSize(
          alignment: Alignment.centerLeft,
          curve: widget.curve,
          duration: widget.duration,
          child: SizedBox(
            width: _chip ? null : kCatalogWidth,
            child: Padding(
              padding: EdgeInsets.only(
                  left: 8.0,
                  top: 4.0,
                  bottom: 4.0,
                  right: widget.onDelete != null ? 4.0 : 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (widget.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: widget.icon,
                    ),
                  if (atomlessLandmark)
                    const Tooltip(
                      message: 'This atom has a landmark with no atom.',
                      child: Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.warning),
                      ),
                    ),
                  if (directionlessLandmark)
                    const Tooltip(
                      message: 'This atom has a landmark with no direction.',
                      child: Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.warning),
                      ),
                    ),
                  if (duplicateLandmark)
                    const Tooltip(
                      message:
                          'This atom has multiple navigatable landmarks with the same direction.',
                      child: Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.warning),
                      ),
                    ),
                  widget.label ??
                      AnimatedBuilder(
                        animation: widget.atom!,
                        builder: (BuildContext context, Widget? child) {
                          return makeTextForIdentifier(
                              context, widget.atom!.identifier!);
                        },
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
      ),
    );
  }

  void updateWarnings() {
    atomlessLandmark = false;
    directionlessLandmark = false;
    duplicateLandmark = false;
    final Set<String> directions = <String>{};
    if ((widget.atom?['landmark'] as LandmarksPropertyValue?)?.value != null) {
      for (final Landmark landmark
          in (widget.atom!['landmark'] as LandmarksPropertyValue).value) {
        if (landmark.direction == '' || landmark.direction == null) {
          directionlessLandmark = true;
          if (landmark.atom == null) {
            atomlessLandmark = true;
          }
          continue;
        }
        if (landmark.atom == null) {
          atomlessLandmark = true;
          continue;
        }
        if (directions.contains(landmark.direction) &&
            landmark.options.contains('loPermissibleNavigationTarget')) {
          duplicateLandmark = true;
          continue;
        }
        if (landmark.options.contains('loPermissibleNavigationTarget')) {
          directions.add(landmark.direction!);
        }
      }
    }
  }
}
