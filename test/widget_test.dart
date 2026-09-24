import 'package:flutter_test/flutter_test.dart';
import 'package:career_os/core/constants/app_constants.dart';

void main() {
  group('Core Domain & Constants Tests', () {
    test('TaskPriority enum parser works correctly', () {
      expect(TaskPriority.fromString('high'), TaskPriority.high);
      expect(TaskPriority.fromString('HIGH'), TaskPriority.high);
      expect(TaskPriority.fromString('medium'), TaskPriority.medium);
      expect(TaskPriority.fromString('low'), TaskPriority.low);
      expect(TaskPriority.fromString('unknown'), TaskPriority.medium);
    });

    test('TaskStatus enum parser works correctly', () {
      expect(TaskStatus.fromString('todo'), TaskStatus.todo);
      expect(TaskStatus.fromString('inProgress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('completed'), TaskStatus.completed);
      expect(TaskStatus.fromString(null), TaskStatus.todo);
    });

    test('ApplicationStatus enum parser works correctly for all Phase 2 stages', () {
      expect(ApplicationStatus.fromString('saved'), ApplicationStatus.saved);
      expect(ApplicationStatus.fromString('applying'), ApplicationStatus.applying);
      expect(ApplicationStatus.fromString('applied'), ApplicationStatus.applied);
      expect(ApplicationStatus.fromString('screening'), ApplicationStatus.screening);
      expect(ApplicationStatus.fromString('interview'), ApplicationStatus.interview);
      expect(ApplicationStatus.fromString('technical'), ApplicationStatus.technical);
      expect(ApplicationStatus.fromString('hr'), ApplicationStatus.hr);
      expect(ApplicationStatus.fromString('offer'), ApplicationStatus.offer);
      expect(ApplicationStatus.fromString('rejected'), ApplicationStatus.rejected);
      expect(ApplicationStatus.fromString('withdrawn'), ApplicationStatus.withdrawn);
      expect(ApplicationStatus.fromString(null), ApplicationStatus.saved);
    });

    test('ProjectStatus enum parser works correctly', () {
      expect(ProjectStatus.fromString('idea'), ProjectStatus.idea);
      expect(ProjectStatus.fromString('planned'), ProjectStatus.planned);
      expect(ProjectStatus.fromString('in_progress'), ProjectStatus.inProgress);
      expect(ProjectStatus.fromString('inProgress'), ProjectStatus.inProgress);
      expect(ProjectStatus.fromString('paused'), ProjectStatus.paused);
      expect(ProjectStatus.fromString('completed'), ProjectStatus.completed);
      expect(ProjectStatus.fromString('archived'), ProjectStatus.archived);
      expect(ProjectStatus.fromString(null), ProjectStatus.planned);
    });
  });
}
