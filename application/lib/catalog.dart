import 'package:flutter/material.dart';

class Catalog extends StatefulWidget {
  const Catalog({ Key key }): super(key: key);
  @override
  _CatalogState createState() => _CatalogState();
}

class _CatalogState extends State<Catalog> with SingleTickerProviderStateMixin {
  TabController _tabController;

  static const List<Widget> tabs = <Widget>[
    Tab(
      child: Text(
        'Items',
        style: TextStyle(color: Colors.black),
      ),
    ),
    Tab(
      child: Text(
        'Locations',
        style: TextStyle(color: Colors.black),
      ),
    ),
    Tab(
      child: Text(
        'Console',
        style: TextStyle(color: Colors.black),
      ),
    ),
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
              Container(
                color: Colors.red,
              ),
              Container(
                color: Colors.red,
              ),
              Container(),
            ],
          ),
        ),
      ],
    );
  }
}
