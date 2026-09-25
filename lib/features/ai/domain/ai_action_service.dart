import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import 'ai_models.dart';

class AIActionService {
  final AppDatabase _db;

  AIActionService(this._db);

  Future<ActionExecutionResult> executeAction(StructuredActionProposal proposal) async {
    final type = proposal.actionType.toUpperCase();
    final p = proposal.payload;

    try {
      switch (type) {
        case 'CREATE_TASK':
          final id = 'task-${DateTime.now().millisecondsSinceEpoch}';
          final title = p['title'] as String;
          final category = (p['category'] as String?)?.toLowerCase() ?? 'work';
          final priority = (p['priority'] as String?)?.toLowerCase() ?? 'medium';
          final notes = p['notes'] as String?;
          DateTime? dueDate;
          if (p['dueDate'] != null) {
            dueDate = DateTime.tryParse(p['dueDate'].toString());
          }

          await _db.insertTask(TasksCompanion(
            id: Value(id),
            title: Value(title),
            category: Value(category),
            priority: Value(priority),
            status: const Value('todo'),
            notes: Value(notes),
            dueDate: Value(dueDate),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));
          return ActionExecutionResult(
            success: true,
            message: 'Created task "$title"',
          );

        case 'UPDATE_TASK_STATUS':
          final id = p['id'] as String;
          final status = (p['status'] as String).toLowerCase();
          final updated = await _db.updateTaskStatus(id, status);
          if (updated > 0) {
            return ActionExecutionResult(
              success: true,
              message: 'Updated task $id status to "$status"',
            );
          } else {
            return ActionExecutionResult(
              success: false,
              message: 'Task with id "$id" not found',
            );
          }

        case 'SAVE_JOB':
          final id = 'job-${DateTime.now().millisecondsSinceEpoch}';
          final title = p['title'] as String;
          final company = p['company'] as String;
          final location = p['location'] as String?;
          final salary = p['salary'] as String?;
          final skills = p['skills'] as String?;
          final url = p['url'] as String?;

          await _db.insertJob(JobsCompanion(
            id: Value(id),
            title: Value(title),
            company: Value(company),
            location: Value(location),
            salary: Value(salary),
            skills: Value(skills),
            url: Value(url),
            isSaved: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));
          return ActionExecutionResult(
            success: true,
            message: 'Saved job "$title" at $company',
          );

        case 'UPDATE_APPLICATION_STATUS':
          final id = p['id'] as String;
          final status = (p['status'] as String).toLowerCase();
          final updated = await _db.updateApplicationStatus(id, status);
          if (updated > 0) {
            return ActionExecutionResult(
              success: true,
              message: 'Updated application $id status to "$status"',
            );
          } else {
            return ActionExecutionResult(
              success: false,
              message: 'Application with id "$id" not found',
            );
          }

        case 'SET_DSA_REVISION_DATE':
          final id = p['id'] as String;
          DateTime targetDate;
          if (p['daysFromNow'] != null) {
            final days = int.tryParse(p['daysFromNow'].toString()) ?? 1;
            targetDate = DateTime.now().add(Duration(days: days));
          } else if (p['revisionDate'] != null) {
            targetDate = DateTime.tryParse(p['revisionDate'].toString()) ?? DateTime.now().add(const Duration(days: 3));
          } else {
            targetDate = DateTime.now().add(const Duration(days: 3));
          }

          final updated = await _db.setDSARevisionDate(id, targetDate);
          if (updated > 0) {
            return ActionExecutionResult(
              success: true,
              message: 'Scheduled DSA problem revision for ${targetDate.toIso8601String().substring(0, 10)}',
            );
          } else {
            return ActionExecutionResult(
              success: false,
              message: 'DSA problem with id "$id" not found',
            );
          }

        case 'CREATE_EXPENSE':
          final id = 'exp-${DateTime.now().millisecondsSinceEpoch}';
          final amount = (p['amount'] as num).toDouble();
          final category = p['category'] as String? ?? 'General';
          final description = p['description'] as String;
          final notes = p['notes'] as String?;

          await _db.insertExpense(ExpensesCompanion(
            id: Value(id),
            amount: Value(amount),
            date: Value(DateTime.now()),
            category: Value(category),
            description: Value(description),
            notes: Value(notes),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));
          return ActionExecutionResult(
            success: true,
            message: 'Recorded expense of \$${amount.toStringAsFixed(2)} for "$description"',
          );

        case 'CREATE_INCOME':
          final id = 'inc-${DateTime.now().millisecondsSinceEpoch}';
          final amount = (p['amount'] as num).toDouble();
          final category = p['category'] as String? ?? 'Salary';
          final source = p['source'] as String;
          final notes = p['notes'] as String?;

          await _db.insertIncome(IncomesCompanion(
            id: Value(id),
            amount: Value(amount),
            date: Value(DateTime.now()),
            category: Value(category),
            source: Value(source),
            notes: Value(notes),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));
          return ActionExecutionResult(
            success: true,
            message: 'Recorded income of \$${amount.toStringAsFixed(2)} from "$source"',
          );

        default:
          return ActionExecutionResult(
            success: false,
            message: 'Unknown action type "$type"',
          );
      }
    } catch (e) {
      return ActionExecutionResult(
        success: false,
        message: 'Failed to execute action: $e',
      );
    }
  }
}
