import 'package:flutter/material.dart';

import 'data_model.dart';
import 'disposition.dart';

class AtomDescription {
  const AtomDescription({
    this.identifier,
    this.className,
    this.properties,
  });

  final String identifier;
  final String className;
  final Map<String, PropertyValue> properties;

  Atom create(AtomsDisposition disposition) {
    return disposition.add()
      ..identifier = Identifier.split(identifier)
      ..className = className
      ..addAll(properties);
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
          atoms: const <AtomDescription>[
            AtomDescription(
              identifier: 'room',
              className: 'TGroundLocation',
              properties: <String, PropertyValue>{
                'name': StringPropertyValue('room'),
                'definiteName': StringPropertyValue('the room'),
                'indefiniteName': StringPropertyValue('a room'),
                'ground': AtomPropertyValuePlaceholder('room_ground'),
              },
            ),
            AtomDescription(
              identifier: 'room_ground',
              className: 'TEarthGround',
              properties: <String, PropertyValue>{
                'name': StringPropertyValue('ground'),
                'pattern': StringPropertyValue('((flat? ground/grounds) (flat? (surface/surfaces of)? earth))@'),
                'description': StringPropertyValue('The ground is a flat surface of earth.'),
                'mass': LiteralPropertyValue('tmLudicrous'),
                'size': LiteralPropertyValue('tsLudicrous'),
              },
            ),
          ],
          onCreated: onCreated,
          icon: const Icon(Icons.landscape),
        ),
        Blueprint(
          header: 'Sky backdrop',
          atoms: const <AtomDescription>[],
          onCreated: onCreated,
          icon: const Icon(Icons.cloud),
        ),
        Blueprint(
          header: 'Indoor room',
          atoms: const <AtomDescription>[],
          onCreated: onCreated,
          icon: const Icon(Icons.insert_photo),
        ),
        Blueprint(
          header: 'Door threshold',
          atoms: const <AtomDescription>[],
          onCreated: onCreated,
          icon: const Icon(Icons.sensor_door),
        ),
      ],
    );
  }
}

class Blueprint extends StatelessWidget {
  const Blueprint({
    Key key,
    @required this.header,
    @required this.icon,
    @required this.atoms,
    this.onCreated,
  }) : assert(atoms != null),
       super(key: key);

  final String header;
  final Widget icon;
  final List<AtomDescription> atoms;
  final VoidCallback onCreated;

  void _handleCreate(BuildContext context) {
    assert(this.atoms.isNotEmpty);
    final List<Atom> atoms = this.atoms.map<Atom>((AtomDescription description) => description.create(AtomsDisposition.of(context))).toList();
    Atom _lookupAtom(String identifier, { Atom ignore }) {
      final List<Atom> matches = atoms
        .where((Atom atom) => atom != ignore && atom.identifier.matches(identifier))
        .toList();
      assert(matches.length == 1, 'could not find unique $identifier; found $matches in $atoms');
      return matches.single;
    }
    for (final Atom atom in atoms)
      atom.resolveIdentifiers(_lookupAtom);
    AtomsDisposition.of(context).addAll(atoms);
    EditorDisposition.of(context).current = atoms.first;
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