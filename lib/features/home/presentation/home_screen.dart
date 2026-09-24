import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/quick_add_modal.dart';
import 'widgets/career_snapshot_section.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/freelance_snapshot_section.dart';
import 'widgets/projects_snapshot_section.dart';
import 'widgets/quick_actions_bar.dart';
import 'widgets/today_overview_card.dart';
import 'widgets/today_tasks_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger reactive updates across providers
          await Future.delayed(const Duration(milliseconds: 200));
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(),
              SizedBox(height: 16),
              TodayOverviewCard(),
              SizedBox(height: 20),
              QuickActionsBar(),
              SizedBox(height: 20),
              TodayTasksSection(),
              SizedBox(height: 20),
              CareerSnapshotSection(),
              SizedBox(height: 20),
              FreelanceSnapshotSection(),
              SizedBox(height: 20),
              ProjectsSnapshotSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickAddModal(context),
        tooltip: 'Quick Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
