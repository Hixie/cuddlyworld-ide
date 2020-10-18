import 'package:flutter/material.dart';
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
            children: const <Widget>[
              Placeholder(color: Colors.blue),
              Placeholder(color: Colors.teal),
              ConsoleTab(),
            ],
          ),
        ),
      ],
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        TextField(
          controller: _username,
          decoration: const InputDecoration(
            hintText: 'Username',
          ),
        ),
        TextField(
          controller: _password,
          decoration: const InputDecoration(
            hintText: 'Password',
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
