import '../jobs/normalized_job.dart';
import 'matching_config.dart';

enum FeedbackAction {
  interested,
  notInterested,
  applied,
  rejected,
  alreadyApplied,
  saved,
  unsaved,
  hideCompany,
  hideRole,
}

class UserFeedbackRecord {
  final String jobId;
  final FeedbackAction action;
  final String companyNorm;
  final String roleFamily;
  final DateTime createdAt;

  const UserFeedbackRecord({
    required this.jobId,
    required this.action,
    required this.companyNorm,
    required this.roleFamily,
    required this.createdAt,
  });
}

class FeedbackModel {
  FeedbackModel._();

  static int computeAdjustment({
    required NormalizedJob job,
    required List<UserFeedbackRecord> history,
    required MatchingConfig config,
  }) {
    var adj = 0;
    var rejectionsInRoleFamily = 0;
    var rejectionsForCompany = 0;

    for (final record in history) {
      if (record.action == FeedbackAction.notInterested || record.action == FeedbackAction.rejected) {
        if (record.roleFamily == job.roleFamily) {
          rejectionsInRoleFamily++;
        }
        if (record.companyNorm == job.companyNorm) {
          rejectionsForCompany++;
        }
      } else if (record.action == FeedbackAction.interested ||
          record.action == FeedbackAction.saved ||
          record.action == FeedbackAction.applied) {
        if (record.roleFamily == job.roleFamily) {
          adj += 2;
        }
      }
    }

    if (rejectionsInRoleFamily >= 3) {
      adj -= 5;
    }
    if (rejectionsForCompany >= 2) {
      adj -= 5;
    }

    return adj.clamp(config.feedbackAdjMin, config.feedbackAdjMax);
  }
}
