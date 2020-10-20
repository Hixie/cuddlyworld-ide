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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          tabs: tabs,
          controller: _tabController,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              ItemsTab(),
              const Placeholder(color: Colors.teal),
              const ConsoleTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class ItemsTab extends StatefulWidget {
  @override
  _ItemsTabState createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab> {
  void func() {
    setState((){});
  }
  List<Thing> things = <Thing>[];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for(final Thing element in things) {
      element.name.removeListener(func);
    }
    things = ThingsDisposition.of(context).things.toList();
    for(final Thing element in things) {
      element.name.addListener(func);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(children: ThingsDisposition.of(context).things.map((Thing e) => Text(e.name.value)).toList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
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
            ServerDisposition.of(context).loginData =
                LoginData(_username.text, _password.text);
          },
          child: const Text('Login'),
        )
      ],
    );
  }
}
