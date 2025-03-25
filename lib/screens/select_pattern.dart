import 'package:flutter/material.dart';
import 'package:rosario/widgets/patterns_collection.dart';

import '../widgets/blueprints.dart';

class SelectPatternScreen extends StatefulWidget {
  static String routeName = '/select';
  const SelectPatternScreen({super.key});

  @override
  State<SelectPatternScreen> createState() => _SelectPatternScreenState();
}

class _SelectPatternScreenState extends State<SelectPatternScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(right: 60.0),
          child: Image.asset(
            'assets/img/rosario-logo.png',
            width: double.infinity,
            height: 40,
            fit: BoxFit.fitHeight,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(
              text: 'Public Patterns',
            ),
            Tab(
              text: 'Blueprints',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          Center(
            child: PatternsCollection(),
          ),
          Center(
            child: Blueprints(),
          ),
        ],
      ),
    );
  }
}
