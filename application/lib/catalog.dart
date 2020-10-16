import 'package:flutter/material.dart';

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
              const Placeholder(color: Colors.blue),
              const Placeholder(color: Colors.teal),
              Container(),
            ],
          ),
        ),
      ],
    );
  }
}
