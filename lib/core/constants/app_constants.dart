class AppConstants {
  static const String appName = 'Risheesh OS';
  static const String appTagline = 'Personal Career & Life Command Center';
  static const String appVersion = '1.0.0+1';

  static const String keyThemeMode = 'app_theme_mode';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String defaultUserName = 'Risheesh';
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
