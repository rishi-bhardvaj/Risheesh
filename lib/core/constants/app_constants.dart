class AppConstants {
  static const String appName = 'Risheesh OS';
  static const String appTagline = 'Personal Career & Life Command Center';
  static const String appVersion = '1.0.0+1';

  static const String keyThemeMode = 'app_theme_mode';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String defaultUserName = 'Risheesh';

  static const List<String> freelancePlatforms = [
    'Upwork',
    'Fiverr',
    'Freelancer',
    'LinkedIn',
    'Direct',
    'Referral',
    'Startup',
    'Other',
  ];

  static const List<String> currencies = [
    'USD',
    'INR',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'SGD',
    'AED',
  ];
}

enum TaskCategory {
  personal('Personal'),
  work('Work');

  final String label;
  const TaskCategory(this.label);

  static TaskCategory fromString(String? val) {
    if (val == null) return TaskCategory.work;
    return TaskCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TaskCategory.work,
    );
  }
}

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  final String label;
  const TaskPriority(this.label);

  static TaskPriority fromString(String? val) {
    if (val == null) return TaskPriority.medium;
    return TaskPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  completed('Completed');

  final String label;
  const TaskStatus(this.label);

  static TaskStatus fromString(String? val) {
    if (val == null) return TaskStatus.todo;
    return TaskStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.replaceAll('_', '').toLowerCase(),
      orElse: () => TaskStatus.todo,
    );
  }
}

enum ApplicationStatus {
  saved('Saved'),
  applying('Applying'),
  applied('Applied'),
  screening('Screening'),
  interview('Interview'),
  technical('Technical'),
  hr('HR Round'),
  offer('Offer'),
  rejected('Rejected'),
  withdrawn('Withdrawn');

  final String label;
  const ApplicationStatus(this.label);

  static ApplicationStatus fromString(String? val) {
    if (val == null) return ApplicationStatus.saved;
    return ApplicationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.replaceAll('_', '').toLowerCase(),
      orElse: () => ApplicationStatus.saved,
    );
  }
}

enum ProjectStatus {
  idea('Idea'),
  planned('Planned'),
  inProgress('In Progress'),
  paused('Paused'),
  completed('Completed'),
  archived('Archived');

  final String label;
  const ProjectStatus(this.label);

  static ProjectStatus fromString(String? val) {
    if (val == null) return ProjectStatus.planned;
    return ProjectStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.replaceAll('_', '').toLowerCase(),
      orElse: () => ProjectStatus.planned,
    );
  }
}

enum LeadStatus {
  newLead('NEW_LEAD', 'New Lead'),
  researching('RESEARCHING', 'Researching'),
  contacted('CONTACTED', 'Contacted'),
  replied('REPLIED', 'Replied'),
  discussion('DISCUSSION', 'Discussion'),
  proposalSent('PROPOSAL_SENT', 'Proposal Sent'),
  negotiation('NEGOTIATION', 'Negotiation'),
  won('WON', 'Won'),
  lost('LOST', 'Lost');

  final String value;
  final String label;
  const LeadStatus(this.value, this.label);

  static LeadStatus fromString(String? val) {
    if (val == null) return LeadStatus.newLead;
    final normalized = val.toUpperCase().replaceAll(' ', '_');
    return LeadStatus.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => LeadStatus.newLead,
    );
  }
}

enum ClientStatus {
  prospect('PROSPECT', 'Prospect'),
  active('ACTIVE', 'Active'),
  inactive('INACTIVE', 'Inactive');

  final String value;
  final String label;
  const ClientStatus(this.value, this.label);

  static ClientStatus fromString(String? val) {
    if (val == null) return ClientStatus.prospect;
    final normalized = val.toUpperCase().replaceAll(' ', '_');
    return ClientStatus.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => ClientStatus.prospect,
    );
  }
}

enum PaymentStatus {
  expected('EXPECTED', 'Expected'),
  invoiced('INVOICED', 'Invoiced'),
  received('RECEIVED', 'Received'),
  cancelled('CANCELLED', 'Cancelled');

  final String value;
  final String label;
  const PaymentStatus(this.value, this.label);

  static PaymentStatus fromString(String? val) {
    if (val == null) return PaymentStatus.expected;
    final normalized = val.toUpperCase().replaceAll(' ', '_');
    return PaymentStatus.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => PaymentStatus.expected,
    );
  }
}

const List<String> freelancePlatforms = [
  'Upwork',
  'Fiverr',
  'Freelancer',
  'LinkedIn',
  'Direct',
  'Referral',
  'Startup',
  'Other',
];

const List<String> currencies = [
  'USD',
  'INR',
  'EUR',
  'GBP',
  'CAD',
  'AUD',
  'SGD',
];

// --- Phase 5: DSA Enums & Constants ---
enum DSADifficulty {
  easy('EASY', 'Easy'),
  medium('MEDIUM', 'Medium'),
  hard('HARD', 'Hard');

  final String value;
  final String label;
  const DSADifficulty(this.value, this.label);

  static DSADifficulty fromString(String? val) {
    if (val == null) return DSADifficulty.medium;
    final normalized = val.toUpperCase().replaceAll(' ', '_');
    return DSADifficulty.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => DSADifficulty.medium,
    );
  }
}

enum DSAStatus {
  todo('TODO', 'To Do'),
  attempted('ATTEMPTED', 'Attempted'),
  solved('SOLVED', 'Solved'),
  needsRevision('NEEDS_REVISION', 'Needs Revision');

  final String value;
  final String label;
  const DSAStatus(this.value, this.label);

  static DSAStatus fromString(String? val) {
    if (val == null) return DSAStatus.todo;
    final normalized = val.toUpperCase().replaceAll(' ', '_');
    return DSAStatus.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => DSAStatus.todo,
    );
  }
}

const List<String> dsaPlatforms = [
  'LeetCode',
  'Codeforces',
  'HackerRank',
  'GeeksforGeeks',
  'InterviewBit',
  'CodeChef',
  'Other',
];

const List<String> dsaTopics = [
  'Arrays',
  'Strings',
  'Linked Lists',
  'Stacks',
  'Queues',
  'Hashing',
  'Trees',
  'Graphs',
  'Heaps',
  'Sorting',
  'Searching',
  'Recursion',
  'Dynamic Programming',
  'Greedy',
  'Backtracking',
  'Bit Manipulation',
  'Two Pointers',
  'Sliding Window',
  'Trie',
  'Math',
  'Other',
];

// --- Phase 5: Learning & Resources Enums ---
enum SkillLevel {
  beginner('BEGINNER', 'Beginner'),
  basic('BASIC', 'Basic'),
  intermediate('INTERMEDIATE', 'Intermediate'),
  advanced('ADVANCED', 'Advanced');

  final String value;
  final String label;
  const SkillLevel(this.value, this.label);

  static SkillLevel fromString(String? val) {
    if (val == null) return SkillLevel.beginner;
    final normalized = val.toUpperCase().replaceAll(' ', '_');
    return SkillLevel.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => SkillLevel.beginner,
    );
  }
}

enum ResourceType {
  course('COURSE', 'Course'),
  documentation('DOCUMENTATION', 'Documentation'),
  github('GITHUB', 'GitHub Repo'),
  video('VIDEO', 'Video / Playlist'),
  article('ARTICLE', 'Article / Blog'),
  book('BOOK', 'Book'),
  tutorial('TUTORIAL', 'Tutorial'),
  other('OTHER', 'Other');

  final String value;
  final String label;
  const ResourceType(this.value, this.label);

  static ResourceType fromString(String? val) {
    if (val == null) return ResourceType.documentation;
    final normalized = val.toUpperCase().replaceAll(' ', '_');
    return ResourceType.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => ResourceType.documentation,
    );
  }
}

enum ResourceStatus {
  toRead('TO_READ', 'To Read / Watch'),
  learning('LEARNING', 'In Progress'),
  completed('COMPLETED', 'Completed'),
  reference('REFERENCE', 'Reference');

  final String value;
  final String label;
  const ResourceStatus(this.value, this.label);

  static ResourceStatus fromString(String? val) {
    if (val == null) return ResourceStatus.toRead;
    final normalized = val.toUpperCase().replaceAll(' ', '_');
    return ResourceStatus.values.firstWhere(
      (e) => e.value == normalized || e.name.toUpperCase() == normalized,
      orElse: () => ResourceStatus.toRead,
    );
  }
}

const List<String> skillCategories = [
  'Language',
  'Framework',
  'Backend',
  'Frontend',
  'Mobile',
  'DevOps & Cloud',
  'System Design',
  'DSA & Algorithms',
  'Database',
  'AI / ML',
  'Soft Skills',
  'Other',
];

// --- Phase 5: Finance Categories ---
const List<String> expenseCategories = [
  'Food & Dining',
  'Transport',
  'Shopping',
  'Subscriptions',
  'Bills & Utilities',
  'Entertainment',
  'Health & Fitness',
  'Education',
  'Housing & Rent',
  'Investment',
  'Other',
];

const List<String> incomeCategories = [
  'Salary',
  'Freelance / Client',
  'Investment',
  'Bonus',
  'Rental',
  'Gift',
  'Other',
];
