import 'package:flutter/material.dart';

import '../../../shared/widgets/ui_kit.dart';
import 'dsa_tab.dart';
import 'habits_tab.dart';
import 'reflection_tab.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenTitle(title: 'Track', subtitle: 'LeetCode, habits and daily reflection'),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [Tab(text: 'LeetCode'), Tab(text: 'Habits'), Tab(text: 'Reflection')],
              ),
              Expanded(child: TabBarView(children: [DsaTab(), HabitsTab(), ReflectionTab()])),
            ],
          ),
        ),
      ),
    );
  }
}
