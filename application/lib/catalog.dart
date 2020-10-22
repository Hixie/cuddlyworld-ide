import 'package:flutter/material.dart';
import 'data_model.dart';
import 'disposition.dart';

typedef TabSwitchHandler = void Function(CatalogTab newTabState);

class Catalog extends StatefulWidget {
  const Catalog({Key key, this.onTabSwitch, this.initialTab}) : super(key: key);
  final TabSwitchHandler onTabSwitch;
  final CatalogTab initialTab;
  @override
  _CatalogState createState() => _CatalogState();
}

enum CatalogTab { items, locations, console }

class _CatalogState extends State<Catalog> with SingleTickerProviderStateMixin {
  TabController _tabController;

  static const List<Widget> tabs = <Widget>[
    Tab(text: 'Items'),
    Tab(text: 'Locations'),
    Tab(text: 'Console'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        vsync: this, length: tabs.length, initialIndex: widget.initialTab.index)
      ..addListener(() {
        if (widget.onTabSwitch != null) {
          widget.onTabSwitch(CatalogTab.values[_tabController.index]);
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Widget get _currentFloatingActionButton {
    switch (CatalogTab.values[_tabController.index]) {
      case CatalogTab.console:
        return null;
      case CatalogTab.locations:
        return FloatingActionButton(
          onPressed: () {
            EditorDisposition.of(context).current = LocationsDisposition.of(context).add();
          },
          child: const Icon(Icons.add),
        );
      case CatalogTab.items:
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
                ConsoleTab(),
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
  void _handleListUpdate() {
    setState((){
      atoms.sort((Atom a, Atom b) => a.name.value.compareTo(b.name.value));
    });
  }
  List<Atom> atoms = <Atom>[];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for(final Atom element in atoms) {
      element.name.removeListener(_handleListUpdate);
    }
    atoms = widget.disposition(context).atoms.toList();
    _handleListUpdate();
    for(final Atom element in atoms) {
      element.name.addListener(_handleListUpdate);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for(final Atom element in atoms) {
      element.name.removeListener(_handleListUpdate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: atoms.map<Widget>((Atom e) => DraggableText(atom: e)).toList());
  }
}

class ConsoleTab extends StatefulWidget {
  const ConsoleTab({Key key}) : super(key: key);
  @override
  _ConsoleTabState createState() => _ConsoleTabState();
}

class _ConsoleTabState extends State<ConsoleTab> {
  TextEditingController _username;
  TextEditingController _password;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _username = TextEditingController(text: ServerDisposition.of(context).username);
    _password = TextEditingController(text: ServerDisposition.of(context).password);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _username,
            decoration: const InputDecoration(
              hintText: 'Username',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _password,
            decoration: const InputDecoration(
              hintText: 'Password',
            ),
            enableSuggestions: false,
            autocorrect: false, 
            obscureText: true,
          ),
        ),
        FlatButton(
          onPressed: () {
            ServerDisposition.of(context).setLoginData(_username.text, _password.text);
          },
          child: const Text('Login'),
        )
      ],
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
    return FlatButton(
      color: widget.atom == EditorDisposition.of(context).current ? Colors.yellow : Colors.white,
      onPressed: () {
        setState(() {
          EditorDisposition.of(context).current = widget.atom;
        });
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.atom.name.value.isEmpty ? '<unnamed>' : widget.atom.name.value,
          style: widget.atom.name.value.isEmpty ? const TextStyle(fontStyle: FontStyle.italic) : null,
        ),
      ),
    );
  }
}