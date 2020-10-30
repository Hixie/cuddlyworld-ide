import 'package:flutter/material.dart';

import 'data_model.dart';
import 'disposition.dart';

class AtomDescription {
  AtomDescription();
  Atom create(AtomsDisposition disposition) {
    return disposition.add();
  }
}

class TemplateLibrary extends StatelessWidget {
  const TemplateLibrary({ Key key, @required this.onCreated }) : super(key: key);

  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 350.0,
      children: <Widget>[
        Blueprint(
          header: 'Outdoor room',
          model: AtomDescription(
            // TODO(ianh): describe outdoor room
          ),
          onCreated: onCreated,
          icon: const Icon(Icons.landscape),
        ),
        Blueprint(
          header: 'Sky backdrop',
          model: AtomDescription(
            // TODO(ianh): describe sky backdrop
          ),
          onCreated: onCreated,
          icon: const Icon(Icons.cloud),
        ),
        Blueprint(
          header: 'Indoor room',
          model: AtomDescription(
            // TODO(ianh): describe indoor room
          ),
          onCreated: onCreated,
          icon: const Icon(Icons.insert_photo),
        ),
        Blueprint(
          header: 'Door threshold',
          model: AtomDescription(
            // TODO(ianh): describe door threshold and door
          ),
          onCreated: onCreated,
          icon: const Icon(Icons.sensor_door),
        ),
      ],
    );
  }
}

class Blueprint extends StatelessWidget {
  const Blueprint({ Key key, this.header, this.icon, this.model, this.onCreated, }) : super(key: key);

  final String header;
  final Widget icon;
  final AtomDescription model;
  final VoidCallback onCreated;

  void _handleCreate(BuildContext context) {
    EditorDisposition.of(context).current = model.create(AtomsDisposition.of(context));
    if (onCreated != null)
      onCreated();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: Theme.of(context).colorScheme.background,
        elevation: 1.0,
        clipBehavior: Clip.antiAlias,
        child: GridTile(
          header: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  color,
                  color.withOpacity(0.25),
                ],
              ),
            ),
            child: GridTileBar(
              title: Text(
                header,
                textAlign: TextAlign.center,
                style: Theme.of(context).primaryTextTheme.headline6,
              ),
            ),
          ),
          child: InkWell(
            onTap: () { _handleCreate(context); },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 48.0, 12.0, 12.0),
              child: FittedBox(
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}