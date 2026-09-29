import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/ui_kit.dart';
import 'add_edit_resume_dialog.dart';
import 'applications_view.dart';
import 'live_jobs_view.dart';
import 'resume_vault_view.dart';
import 'salary_insights_view.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenTitle(
                title: 'Career',
                subtitle: 'Live jobs matched to your profile',
                actions: [
                  IconButton(
                    tooltip: 'Career profile',
                    onPressed: () => context.push('/career/profile'),
                    icon: const Icon(Icons.badge_outlined),
                  ),
                ],
              ),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [Tab(text: 'Jobs'), Tab(text: 'Applied'), Tab(text: 'Resume'), Tab(text: 'Salary')],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const LiveJobsView(),
                    const ApplicationsView(),
                    Scaffold(
                      floatingActionButton: FloatingActionButton.extended(
                        heroTag: 'add-resume',
                        onPressed: () => showDialog(context: context, builder: (_) => const AddEditResumeDialog()),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Add resume'),
                      ),
                      body: const ResumeVaultView(),
                    ),
                    const SalaryInsightsView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
