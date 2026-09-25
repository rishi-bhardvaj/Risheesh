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

    test('LeadStatus enum parser works correctly across pipeline stages', () {
      expect(LeadStatus.fromString('new_lead'), LeadStatus.newLead);
      expect(LeadStatus.fromString('researching'), LeadStatus.researching);
      expect(LeadStatus.fromString('contacted'), LeadStatus.contacted);
      expect(LeadStatus.fromString('replied'), LeadStatus.replied);
      expect(LeadStatus.fromString('discussion'), LeadStatus.discussion);
      expect(LeadStatus.fromString('proposal_sent'), LeadStatus.proposalSent);
      expect(LeadStatus.fromString('negotiation'), LeadStatus.negotiation);
      expect(LeadStatus.fromString('won'), LeadStatus.won);
      expect(LeadStatus.fromString('lost'), LeadStatus.lost);
      expect(LeadStatus.fromString('unknown_val'), LeadStatus.newLead);
      expect(LeadStatus.fromString(null), LeadStatus.newLead);
    });

    test('ClientStatus enum parser works correctly', () {
      expect(ClientStatus.fromString('prospect'), ClientStatus.prospect);
      expect(ClientStatus.fromString('active'), ClientStatus.active);
      expect(ClientStatus.fromString('inactive'), ClientStatus.inactive);
      expect(ClientStatus.fromString(null), ClientStatus.prospect);
    });

    test('PaymentStatus enum parser works correctly', () {
      expect(PaymentStatus.fromString('expected'), PaymentStatus.expected);
      expect(PaymentStatus.fromString('invoiced'), PaymentStatus.invoiced);
      expect(PaymentStatus.fromString('received'), PaymentStatus.received);
      expect(PaymentStatus.fromString('cancelled'), PaymentStatus.cancelled);
      expect(PaymentStatus.fromString(null), PaymentStatus.expected);
    });

    test('Freelance platforms and currencies lists are available', () {
      expect(freelancePlatforms.contains('Upwork'), true);
      expect(freelancePlatforms.contains('LinkedIn'), true);
      expect(freelancePlatforms.contains('Direct'), true);
      expect(currencies.contains('USD'), true);
      expect(currencies.contains('INR'), true);
      expect(currencies.contains('EUR'), true);
    });

    test('Phase 5 Track Module enums and parsers work correctly', () {
      // DSADifficulty
      expect(DSADifficulty.fromString('EASY'), DSADifficulty.easy);
      expect(DSADifficulty.fromString('MEDIUM'), DSADifficulty.medium);
      expect(DSADifficulty.fromString('HARD'), DSADifficulty.hard);
      expect(DSADifficulty.fromString('unknown'), DSADifficulty.medium);

      // DSAStatus
      expect(DSAStatus.fromString('TODO'), DSAStatus.todo);
      expect(DSAStatus.fromString('ATTEMPTED'), DSAStatus.attempted);
      expect(DSAStatus.fromString('SOLVED'), DSAStatus.solved);
      expect(DSAStatus.fromString('NEEDS_REVISION'), DSAStatus.needsRevision);
      expect(DSAStatus.fromString(null), DSAStatus.todo);

      // SkillLevel
      expect(SkillLevel.fromString('BEGINNER'), SkillLevel.beginner);
      expect(SkillLevel.fromString('BASIC'), SkillLevel.basic);
      expect(SkillLevel.fromString('INTERMEDIATE'), SkillLevel.intermediate);
      expect(SkillLevel.fromString('ADVANCED'), SkillLevel.advanced);

      // ResourceType
      expect(ResourceType.fromString('BOOK'), ResourceType.book);
      expect(ResourceType.fromString('COURSE'), ResourceType.course);
      expect(ResourceType.fromString('VIDEO'), ResourceType.video);
      expect(ResourceType.fromString('ARTICLE'), ResourceType.article);
      expect(ResourceType.fromString('GITHUB'), ResourceType.github);
      expect(ResourceType.fromString('DOCUMENTATION'), ResourceType.documentation);

      // ResourceStatus
      expect(ResourceStatus.fromString('TO_READ'), ResourceStatus.toRead);
      expect(ResourceStatus.fromString('LEARNING'), ResourceStatus.learning);
      expect(ResourceStatus.fromString('COMPLETED'), ResourceStatus.completed);
      expect(ResourceStatus.fromString('REFERENCE'), ResourceStatus.reference);

      // Lists
      expect(dsaPlatforms.contains('LeetCode'), true);
      expect(dsaTopics.contains('Dynamic Programming'), true);
      expect(skillCategories.contains('System Design'), true);
      expect(incomeCategories.contains('Salary'), true);
      expect(expenseCategories.contains('Housing & Rent'), true);
    });
  });
}
