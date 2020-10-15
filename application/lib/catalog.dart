import 'package:flutter/material.dart';

class Catalog extends StatefulWidget {
  @override
  _CatalogState createState() => _CatalogState();
}

class _CatalogState extends State<Catalog> with SingleTickerProviderStateMixin {
  TabController _tabController;

  final List<Tab> tabs = [
    Tab(
      child: Text(
        "Items",
        style: TextStyle(color: Colors.black),
      ),
    ),
    Tab(
      child: Text(
        "Locations",
        style: TextStyle(color: Colors.black),
      ),
    ),
    Tab(
      child: Text(
        "Console",
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
      children: [
        TabBar(
          tabs: tabs,
          controller: _tabController,
        ),
        Expanded(
          child: TabBarView(children: [
            Container(
              color: Colors.red,
            ),
            Container(
              color: Colors.red,
            ),
            Container(),
          ], controller: _tabController),
        ),
      ],
    );
  }
}
