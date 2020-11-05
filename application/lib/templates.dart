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
  const TemplateLibrary({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 350.0,
      children: const <Widget>[
        Blueprint(
          header: 'Outdoor room',
          atoms: <AtomDescription>[
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
          icon: Icon(Icons.landscape),
        ),
        Blueprint(
          header: 'Sky backdrop',
          atoms: <AtomDescription>[
            AtomDescription(
              identifier: 'skybox',
              className: 'TBackdrop',
              properties: <String, PropertyValue>{
                'source': AtomPropertyValuePlaceholder('sky'),
                'position': LiteralPropertyValue('tpAtImplicit'),
              },
            ),
            AtomDescription(
              identifier: 'sky',
              className: 'TScenery',
              properties: <String, PropertyValue>{
                'name': StringPropertyValue('sky'),
                'pattern': StringPropertyValue('((blue cloudy sunny)* sky/skies)'),
                'description': StringPropertyValue('The sky is mostly blue, with a few clouds and the sun.'),
                'findDescription': StringPropertyValue('It\'s all around you. Mainly above you.'),
                'cannotMoveExcuse': StringPropertyValue('You can\'t reach the sky.'),
                'opened': BooleanPropertyValue(true),
                'mass': LiteralPropertyValue('tmLudicrous'),
                'size': LiteralPropertyValue('tsLudicrous'),
                'child': ChildrenPropertyValuePlaceholder(<PositionedAtomPlaceholder>[
                  PositionedAtomPlaceholder('tpEmbedded', 'clouds'),
                  PositionedAtomPlaceholder('tpEmbedded', 'sun'),
                ]),
              },
            ),
            AtomDescription(
              identifier: 'clouds',
              className: 'TDescribedPhysicalThing',
              properties: <String, PropertyValue>{
                'name': StringPropertyValue('clouds'),
                'pattern': StringPropertyValue('(fluffy white)* (cloud/clouds (water vapor/vapors)%)@'),
                'description': StringPropertyValue('The clouds appear to be made of cotton, but are actually made of water vapor.'),
                'mass': LiteralPropertyValue('tmPonderous'),
                'size': LiteralPropertyValue('tsLudicrous'),
              },
            ),
            AtomDescription(
              identifier: 'sun',
              className: 'TScenery',
              properties: <String, PropertyValue>{
                'name': StringPropertyValue('sun'),
                'pattern': StringPropertyValue('(((bright yellow)% (sun/suns star/stars)@) ((nearly? perfect)? sphere/spheres) ((nearly? perfect)? sphere/spheres of hot? plasma))@'),
                'description': StringPropertyValue('The sun is a nearly perfect sphere of hot plasma, heated to incandescence by nuclear fusion reactions in its core.'),
                'findDescription': StringPropertyValue('After a long search, you finally determine the sun is THE BRIGHT YELLOW STAR ABOVE YOU.'),
                'cannotMoveExcuse': StringPropertyValue('Aside from not being able to reach the star, there is the issue that even approaching it would likely vaporize you.'),
                'opened': BooleanPropertyValue(false),
                'mass': LiteralPropertyValue('tmLudicrous'),
                'size': LiteralPropertyValue('tsLudicrous'),
                'child': ChildrenPropertyValuePlaceholder(<PositionedAtomPlaceholder>[
                  PositionedAtomPlaceholder('tpPartOfImplicit', 'plasma'),
                ]),
              },
            ),
            AtomDescription(
              identifier: 'plasma',
              className: 'TFeature',
              properties: <String, PropertyValue>{
                'name': StringPropertyValue('plasma'),
                'pattern': StringPropertyValue('hot? plasma/plasmas'),
                'description': StringPropertyValue('The sun\'s plasma is its blood.'),
              },
            ),
          ],
          icon: Icon(Icons.cloud),
        ),
        Blueprint(
          header: 'Indoor room',
          atoms: <AtomDescription>[],
          icon: Icon(Icons.insert_photo),
        ),
        Blueprint(
          header: 'Door threshold',
          atoms: <AtomDescription>[],
          icon: Icon(Icons.sensor_door),
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
  }) : assert(atoms != null),
       super(key: key);

  final String header;
  final Widget icon;
  final List<AtomDescription> atoms;

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
        child: InkWell(
          onTap: () { _handleCreate(context); },
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