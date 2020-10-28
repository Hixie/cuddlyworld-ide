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
  TabController _tabController;

  static const List<Widget> tabs = <Widget>[
    Tab(text: 'Items'),
    Tab(text: 'Locations'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: tabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Widget get _currentFloatingActionButton {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton(
          onPressed: () {
            EditorDisposition.of(context).current = LocationsDisposition.of(context).add();
          },
          child: const Icon(Icons.add),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () {
            EditorDisposition.of(context).current = ThingsDisposition.of(context).add();
          },
          child: const Icon(Icons.add),
        );
    }
    throw Exception();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          tabs: tabs,
          controller: _tabController,
        ),
        Expanded(
          child: Scaffold(
            body: TabBarView(
              controller: _tabController,
              children: const <Widget>[
                ItemsTab(),
                LocationsTab(),
              ],
            ),
            floatingActionButton: _currentFloatingActionButton,
          ),
        ),
      ],
    );
  }
}

abstract class AtomTab<T extends Atom> extends StatefulWidget {
  const AtomTab({Key key}): super(key: key);

  @override
  _AtomTabState<T> createState() => _AtomTabState<T>();

  AtomDisposition<T> disposition(BuildContext context);

}

class ItemsTab extends AtomTab<Thing> {
  const ItemsTab({Key key}): super(key: key);

  @override
  AtomDisposition<Thing> disposition(BuildContext context) => ThingsDisposition.of(context);

}

class LocationsTab extends AtomTab<Location> {
  const LocationsTab({Key key}): super(key: key);

  @override
  AtomDisposition<Location> disposition(BuildContext context) => LocationsDisposition.of(context);

}

class _AtomTabState<T extends Atom> extends State<AtomTab<T>> {
 
  List<Atom> atoms = <Atom>[];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final Atom element in atoms) {
      element.removeListener(_handleListUpdate);
    }
    atoms = widget.disposition(context).atoms.toList();
    _handleListUpdate();
    for (final Atom element in atoms) {
      element.addListener(_handleListUpdate);
    }
  }

  void _handleListUpdate() {
    setState((){
      atoms.sort((Atom a, Atom b) => a.identifier.compareTo(b.identifier));
    });
  }

  @override
  void dispose() {
    super.dispose();
    for (final Atom element in atoms) {
      element.removeListener(_handleListUpdate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: atoms.map<Widget>((Atom e) => DraggableText(atom: e)).toList());
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
      child: FlatButton(
        color: widget.atom == EditorDisposition.of(context).current ? Colors.yellow : null,
        onPressed: () {
          setState(() {
            EditorDisposition.of(context).current = widget.atom;
          });
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: makeTextForIdentifier(context, widget.atom.identifier, widget.atom.className),
        ),
      ),
    );
  }
}
