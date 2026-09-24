import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

// --- Snapshot Model ---
class FreelanceSnapshot {
  final int totalLeads;
  final int activeLeads;
  final int proposalsSent;
  final int wonLeads;
  final int followUpsDueToday;
  final int followUpsOverdue;
  final int activeProjects;
  final int totalClients;
  final double totalExpectedRevenue;
  final double totalReceivedRevenue;
  final String primaryCurrency;

  const FreelanceSnapshot({
    required this.totalLeads,
    required this.activeLeads,
    required this.proposalsSent,
    required this.wonLeads,
    required this.followUpsDueToday,
    required this.followUpsOverdue,
    required this.activeProjects,
    required this.totalClients,
    required this.totalExpectedRevenue,
    required this.totalReceivedRevenue,
    this.primaryCurrency = 'USD',
  });
}

// --- Filter and Sort Enums ---
enum LeadSortOption {
  newest('Newest First'),
  oldest('Oldest First'),
  followUp('Follow-up Date'),
  deadline('Deadline'),
  budgetHighToLow('Budget: High to Low'),
  budgetLowToHigh('Budget: Low to High');

  final String label;
  const LeadSortOption(this.label);
}

enum ClientSortOption {
  name('Client Name (A-Z)'),
  newest('Recently Added'),
  activeFirst('Active Clients First');

  final String label;
  const ClientSortOption(this.label);
}

// --- Filter State ---
class LeadFilterState {
  final String status; // 'all' or specific LeadStatus
  final String platform; // 'all' or specific platform
  final bool hasBudget;
  final bool followUpDueOnly;

  const LeadFilterState({
    this.status = 'all',
    this.platform = 'all',
    this.hasBudget = false,
    this.followUpDueOnly = false,
  });

  LeadFilterState copyWith({
    String? status,
    String? platform,
    bool? hasBudget,
    bool? followUpDueOnly,
  }) {
    return LeadFilterState(
      status: status ?? this.status,
      platform: platform ?? this.platform,
      hasBudget: hasBudget ?? this.hasBudget,
      followUpDueOnly: followUpDueOnly ?? this.followUpDueOnly,
    );
  }

  bool get hasActiveFilters =>
      status != 'all' || platform != 'all' || hasBudget || followUpDueOnly;
}

// --- State Providers ---
final leadSearchQueryProvider = StateProvider<String>((ref) => '');
final leadFilterProvider = StateProvider<LeadFilterState>((ref) => const LeadFilterState());
final leadSortOptionProvider = StateProvider<LeadSortOption>((ref) => LeadSortOption.newest);

final clientSearchQueryProvider = StateProvider<String>((ref) => '');
final clientStatusFilterProvider = StateProvider<String>((ref) => 'all');
final clientSortOptionProvider = StateProvider<ClientSortOption>((ref) => ClientSortOption.name);

final paymentStatusFilterProvider = StateProvider<String>((ref) => 'all');

// --- Stream Providers ---
final allLeadsStreamProvider = StreamProvider<List<FreelanceLead>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllLeads();
});

final allClientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllClients();
});

final allPaymentsStreamProvider = StreamProvider<List<FreelancePayment>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllPayments();
});

final freelanceProjectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchFreelanceProjects();
});

// Single Entity Watchers
final leadByIdProvider = StreamProvider.family<FreelanceLead?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.freelanceLeads)..where((l) => l.id.equals(id))).watchSingleOrNull();
});

final clientByIdProvider = StreamProvider.family<Client?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.clients)..where((c) => c.id.equals(id))).watchSingleOrNull();
});

final paymentByIdProvider = StreamProvider.family<FreelancePayment?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.freelancePayments)..where((p) => p.id.equals(id))).watchSingleOrNull();
});

final clientLeadsProvider = StreamProvider.family<List<FreelanceLead>, String>((ref, clientId) {
  final db = ref.watch(databaseProvider);
  return db.watchLeadsByClientId(clientId);
});

final clientProjectsProvider = StreamProvider.family<List<Project>, String>((ref, clientId) {
  final db = ref.watch(databaseProvider);
  return db.watchProjectsByClientId(clientId);
});

final clientPaymentsProvider = StreamProvider.family<List<FreelancePayment>, String>((ref, clientId) {
  final db = ref.watch(databaseProvider);
  return db.watchPaymentsByClientId(clientId);
});

// --- Computed Filtered Providers ---
final filteredLeadsProvider = Provider<List<FreelanceLead>>((ref) {
  final leadsAsync = ref.watch(allLeadsStreamProvider);
  final query = ref.watch(leadSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(leadFilterProvider);
  final sort = ref.watch(leadSortOptionProvider);

  return leadsAsync.maybeWhen(
    data: (leads) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      var filtered = leads.where((lead) {
        // Search
        if (query.isNotEmpty) {
          final titleMatch = lead.title.toLowerCase().contains(query);
          final clientMatch = lead.clientName?.toLowerCase().contains(query) ?? false;
          final contactMatch = lead.contactName?.toLowerCase().contains(query) ?? false;
          final skillsMatch = lead.skills?.toLowerCase().contains(query) ?? false;
          final platformMatch = lead.platform?.toLowerCase().contains(query) ?? false;
          final descMatch = lead.description?.toLowerCase().contains(query) ?? false;
          if (!titleMatch && !clientMatch && !contactMatch && !skillsMatch && !platformMatch && !descMatch) {
            return false;
          }
        }

        // Status Filter
        if (filter.status != 'all') {
          if (lead.status.toUpperCase() != filter.status.toUpperCase()) {
            return false;
          }
        }

        // Platform Filter
        if (filter.platform != 'all') {
          if ((lead.platform ?? '').toLowerCase() != filter.platform.toLowerCase()) {
            return false;
          }
        }

        // Has Budget
        if (filter.hasBudget && (lead.budget == null || lead.budget! <= 0)) {
          return false;
        }

        // Follow-up Due Only
        if (filter.followUpDueOnly) {
          if (lead.followUpDate == null) return false;
          final fDate = DateTime(lead.followUpDate!.year, lead.followUpDate!.month, lead.followUpDate!.day);
          if (fDate.isAfter(today)) return false;
        }

        return true;
      }).toList();

      // Sort
      switch (sort) {
        case LeadSortOption.newest:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case LeadSortOption.oldest:
          filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case LeadSortOption.followUp:
          filtered.sort((a, b) {
            if (a.followUpDate == null && b.followUpDate == null) return 0;
            if (a.followUpDate == null) return 1;
            if (b.followUpDate == null) return -1;
            return a.followUpDate!.compareTo(b.followUpDate!);
          });
          break;
        case LeadSortOption.deadline:
          filtered.sort((a, b) {
            if (a.deadline == null && b.deadline == null) return 0;
            if (a.deadline == null) return 1;
            if (b.deadline == null) return -1;
            return a.deadline!.compareTo(b.deadline!);
          });
          break;
        case LeadSortOption.budgetHighToLow:
          filtered.sort((a, b) => (b.budget ?? 0).compareTo(a.budget ?? 0));
          break;
        case LeadSortOption.budgetLowToHigh:
          filtered.sort((a, b) => (a.budget ?? 0).compareTo(b.budget ?? 0));
          break;
      }

      return filtered;
    },
    orElse: () => [],
  );
});

final filteredClientsProvider = Provider<List<Client>>((ref) {
  final clientsAsync = ref.watch(allClientsStreamProvider);
  final query = ref.watch(clientSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(clientStatusFilterProvider);
  final sort = ref.watch(clientSortOptionProvider);

  return clientsAsync.maybeWhen(
    data: (clients) {
      var filtered = clients.where((client) {
        if (query.isNotEmpty) {
          final nameMatch = client.name.toLowerCase().contains(query);
          final contactMatch = client.contactName?.toLowerCase().contains(query) ?? false;
          final emailMatch = client.email?.toLowerCase().contains(query) ?? false;
          final platformMatch = client.platform?.toLowerCase().contains(query) ?? false;
          final locationMatch = client.location?.toLowerCase().contains(query) ?? false;
          if (!nameMatch && !contactMatch && !emailMatch && !platformMatch && !locationMatch) {
            return false;
          }
        }

        if (statusFilter != 'all') {
          if (client.status.toUpperCase() != statusFilter.toUpperCase()) {
            return false;
          }
        }

        return true;
      }).toList();

      switch (sort) {
        case ClientSortOption.name:
          filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case ClientSortOption.newest:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case ClientSortOption.activeFirst:
          filtered.sort((a, b) {
            final aActive = a.status.toUpperCase() == 'ACTIVE' ? 0 : 1;
            final bActive = b.status.toUpperCase() == 'ACTIVE' ? 0 : 1;
            if (aActive != bActive) return aActive.compareTo(bActive);
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          break;
      }

      return filtered;
    },
    orElse: () => [],
  );
});

final filteredPaymentsProvider = Provider<List<FreelancePayment>>((ref) {
  final paymentsAsync = ref.watch(allPaymentsStreamProvider);
  final statusFilter = ref.watch(paymentStatusFilterProvider);

  return paymentsAsync.maybeWhen(
    data: (payments) {
      var filtered = payments.where((p) {
        if (statusFilter != 'all') {
          if (p.status.toUpperCase() != statusFilter.toUpperCase()) {
            return false;
          }
        }
        return true;
      }).toList();

      filtered.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return filtered;
    },
    orElse: () => [],
  );
});

// --- Follow-Up Providers ---
final leadsFollowUpDueTodayProvider = Provider<List<FreelanceLead>>((ref) {
  final leads = ref.watch(allLeadsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  return leads.where((l) {
    if (l.followUpDate == null) return false;
    if (l.status.toUpperCase() == 'WON' || l.status.toUpperCase() == 'LOST') return false;
    final f = l.followUpDate!;
    return (f.isAtSameMomentAs(today) || (f.isAfter(today) && f.isBefore(tomorrow)));
  }).toList();
});

final leadsFollowUpOverdueProvider = Provider<List<FreelanceLead>>((ref) {
  final leads = ref.watch(allLeadsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return leads.where((l) {
    if (l.followUpDate == null) return false;
    if (l.status.toUpperCase() == 'WON' || l.status.toUpperCase() == 'LOST') return false;
    final f = DateTime(l.followUpDate!.year, l.followUpDate!.month, l.followUpDate!.day);
    return f.isBefore(today);
  }).toList();
});

final leadsUpcomingFollowUpProvider = Provider<List<FreelanceLead>>((ref) {
  final leads = ref.watch(allLeadsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

  return leads.where((l) {
    if (l.followUpDate == null) return false;
    if (l.status.toUpperCase() == 'WON' || l.status.toUpperCase() == 'LOST') return false;
    final f = DateTime(l.followUpDate!.year, l.followUpDate!.month, l.followUpDate!.day);
    return f.isAfter(tomorrow) || f.isAtSameMomentAs(tomorrow);
  }).toList();
});

// --- Snapshot Provider ---
final freelanceSnapshotProvider = Provider<FreelanceSnapshot>((ref) {
  final leads = ref.watch(allLeadsStreamProvider).valueOrNull ?? [];
  final clients = ref.watch(allClientsStreamProvider).valueOrNull ?? [];
  final payments = ref.watch(allPaymentsStreamProvider).valueOrNull ?? [];
  final projects = ref.watch(freelanceProjectsStreamProvider).valueOrNull ?? [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  int activeLeadsCount = 0;
  int proposalsSentCount = 0;
  int wonLeadsCount = 0;
  int dueTodayCount = 0;
  int overdueCount = 0;

  for (final l in leads) {
    final s = l.status.toUpperCase();
    if (s == 'WON') {
      wonLeadsCount++;
    } else if (s != 'LOST') {
      activeLeadsCount++;
      if (s == 'PROPOSAL_SENT' || s == 'NEGOTIATION') {
        proposalsSentCount++;
      }
      if (l.followUpDate != null) {
        final f = DateTime(l.followUpDate!.year, l.followUpDate!.month, l.followUpDate!.day);
        if (f.isBefore(today)) {
          overdueCount++;
        } else if (f.isAtSameMomentAs(today) || (f.isAfter(today) && f.isBefore(tomorrow))) {
          dueTodayCount++;
        }
      }
    }
  }

  double expectedRevenue = 0.0;
  double receivedRevenue = 0.0;
  for (final p in payments) {
    final status = p.status.toUpperCase();
    if (status == 'RECEIVED') {
      receivedRevenue += p.amount;
    } else if (status == 'EXPECTED' || status == 'INVOICED') {
      expectedRevenue += p.amount;
    }
  }

  final activeProjectsCount = projects.where((p) => p.status != 'completed' && p.status != 'archived').length;

  return FreelanceSnapshot(
    totalLeads: leads.length,
    activeLeads: activeLeadsCount,
    proposalsSent: proposalsSentCount,
    wonLeads: wonLeadsCount,
    followUpsDueToday: dueTodayCount,
    followUpsOverdue: overdueCount,
    activeProjects: activeProjectsCount,
    totalClients: clients.length,
    totalExpectedRevenue: expectedRevenue,
    totalReceivedRevenue: receivedRevenue,
  );
});

// --- Repository ---
class FreelanceRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  FreelanceRepository(this._db);

  // --- Lead Operations ---
  Future<String> addLead({
    required String title,
    String? clientName,
    String? contactName,
    String? contactInfo,
    String? platform,
    String? description,
    String? skills,
    double? budget,
    String currency = 'USD',
    String? url,
    String status = 'NEW_LEAD',
    String? proposal,
    DateTime? deadline,
    DateTime? followUpDate,
    String? followUpNote,
    String? nextAction,
    String? notes,
    DateTime? leadDate,
    String? clientId,
    String? projectId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.insertLead(FreelanceLeadsCompanion(
      id: drift.Value(id),
      title: drift.Value(title.trim()),
      clientName: drift.Value(clientName?.trim().isEmpty ?? true ? null : clientName!.trim()),
      contactName: drift.Value(contactName?.trim().isEmpty ?? true ? null : contactName!.trim()),
      contactInfo: drift.Value(contactInfo?.trim().isEmpty ?? true ? null : contactInfo!.trim()),
      platform: drift.Value(platform),
      description: drift.Value(description?.trim().isEmpty ?? true ? null : description!.trim()),
      skills: drift.Value(skills?.trim().isEmpty ?? true ? null : skills!.trim()),
      budget: drift.Value(budget),
      currency: drift.Value(currency),
      url: drift.Value(url?.trim().isEmpty ?? true ? null : url!.trim()),
      status: drift.Value(status),
      proposal: drift.Value(proposal?.trim().isEmpty ?? true ? null : proposal!.trim()),
      deadline: drift.Value(deadline),
      followUpDate: drift.Value(followUpDate),
      followUpNote: drift.Value(followUpNote?.trim().isEmpty ?? true ? null : followUpNote!.trim()),
      nextAction: drift.Value(nextAction?.trim().isEmpty ?? true ? null : nextAction!.trim()),
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
      leadDate: drift.Value(leadDate ?? now),
      clientId: drift.Value(clientId),
      projectId: drift.Value(projectId),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    ));

    return id;
  }

  Future<bool> updateLead({
    required String id,
    required String title,
    String? clientName,
    String? contactName,
    String? contactInfo,
    String? platform,
    String? description,
    String? skills,
    double? budget,
    String currency = 'USD',
    String? url,
    required String status,
    String? proposal,
    DateTime? deadline,
    DateTime? followUpDate,
    String? followUpNote,
    String? nextAction,
    String? notes,
    DateTime? leadDate,
    String? clientId,
    String? projectId,
    required DateTime createdAt,
  }) async {
    return _db.updateLead(FreelanceLeadsCompanion(
      id: drift.Value(id),
      title: drift.Value(title.trim()),
      clientName: drift.Value(clientName?.trim().isEmpty ?? true ? null : clientName!.trim()),
      contactName: drift.Value(contactName?.trim().isEmpty ?? true ? null : contactName!.trim()),
      contactInfo: drift.Value(contactInfo?.trim().isEmpty ?? true ? null : contactInfo!.trim()),
      platform: drift.Value(platform),
      description: drift.Value(description?.trim().isEmpty ?? true ? null : description!.trim()),
      skills: drift.Value(skills?.trim().isEmpty ?? true ? null : skills!.trim()),
      budget: drift.Value(budget),
      currency: drift.Value(currency),
      url: drift.Value(url?.trim().isEmpty ?? true ? null : url!.trim()),
      status: drift.Value(status),
      proposal: drift.Value(proposal?.trim().isEmpty ?? true ? null : proposal!.trim()),
      deadline: drift.Value(deadline),
      followUpDate: drift.Value(followUpDate),
      followUpNote: drift.Value(followUpNote?.trim().isEmpty ?? true ? null : followUpNote!.trim()),
      nextAction: drift.Value(nextAction?.trim().isEmpty ?? true ? null : nextAction!.trim()),
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
      leadDate: drift.Value(leadDate),
      clientId: drift.Value(clientId),
      projectId: drift.Value(projectId),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(DateTime.now()),
    ));
  }

  Future<int> deleteLead(String id) => _db.deleteLead(id);

  Future<int> updateLeadStatus(String id, String status) => _db.updateLeadStatus(id, status);

  // --- Convert Lead to Client ---
  Future<String> convertLeadToClient({
    required FreelanceLead lead,
    String? clientName,
    String? contactPerson,
    String? email,
    String? phone,
    String? platform,
    String? location,
    String? notes,
  }) async {
    final finalName = (clientName != null && clientName.trim().isNotEmpty)
        ? clientName.trim()
        : (lead.clientName?.trim().isNotEmpty == true ? lead.clientName!.trim() : lead.title);

    final clientId = await addClient(
      name: finalName,
      contactName: contactPerson ?? lead.contactName,
      email: email,
      phone: phone,
      platform: platform ?? lead.platform,
      location: location,
      status: 'ACTIVE',
      notes: notes ?? lead.notes,
    );

    // Update lead with new clientId and mark WON if not already
    await _db.updateLead(lead.toCompanion(true).copyWith(
      clientId: drift.Value(clientId),
      status: const drift.Value('WON'),
      updatedAt: drift.Value(DateTime.now()),
    ));

    return clientId;
  }

  // --- Client Operations ---
  Future<String> addClient({
    required String name,
    String? contactName,
    String? email,
    String? phone,
    String? platform,
    String? location,
    String status = 'ACTIVE',
    String? notes,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.insertClient(ClientsCompanion(
      id: drift.Value(id),
      name: drift.Value(name.trim()),
      contactName: drift.Value(contactName?.trim().isEmpty ?? true ? null : contactName!.trim()),
      email: drift.Value(email?.trim().isEmpty ?? true ? null : email!.trim()),
      phone: drift.Value(phone?.trim().isEmpty ?? true ? null : phone!.trim()),
      platform: drift.Value(platform),
      location: drift.Value(location?.trim().isEmpty ?? true ? null : location!.trim()),
      status: drift.Value(status),
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    ));

    return id;
  }

  Future<bool> updateClient({
    required String id,
    required String name,
    String? contactName,
    String? email,
    String? phone,
    String? platform,
    String? location,
    required String status,
    String? notes,
    required DateTime createdAt,
  }) async {
    return _db.updateClient(ClientsCompanion(
      id: drift.Value(id),
      name: drift.Value(name.trim()),
      contactName: drift.Value(contactName?.trim().isEmpty ?? true ? null : contactName!.trim()),
      email: drift.Value(email?.trim().isEmpty ?? true ? null : email!.trim()),
      phone: drift.Value(phone?.trim().isEmpty ?? true ? null : phone!.trim()),
      platform: drift.Value(platform),
      location: drift.Value(location?.trim().isEmpty ?? true ? null : location!.trim()),
      status: drift.Value(status),
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(DateTime.now()),
    ));
  }

  Future<int> deleteClient(String id) => _db.deleteClient(id);

  // --- Payment Operations ---
  Future<String> addPayment({
    required String clientId,
    String? projectId,
    required double amount,
    String currency = 'USD',
    required DateTime paymentDate,
    String status = 'EXPECTED',
    String? description,
    String? notes,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.insertPayment(FreelancePaymentsCompanion(
      id: drift.Value(id),
      clientId: drift.Value(clientId),
      projectId: drift.Value(projectId),
      amount: drift.Value(amount),
      currency: drift.Value(currency),
      paymentDate: drift.Value(paymentDate),
      status: drift.Value(status),
      description: drift.Value(description?.trim().isEmpty ?? true ? null : description!.trim()),
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    ));

    return id;
  }

  Future<bool> updatePayment({
    required String id,
    required String clientId,
    String? projectId,
    required double amount,
    String currency = 'USD',
    required DateTime paymentDate,
    required String status,
    String? description,
    String? notes,
    required DateTime createdAt,
  }) async {
    return _db.updatePayment(FreelancePaymentsCompanion(
      id: drift.Value(id),
      clientId: drift.Value(clientId),
      projectId: drift.Value(projectId),
      amount: drift.Value(amount),
      currency: drift.Value(currency),
      paymentDate: drift.Value(paymentDate),
      status: drift.Value(status),
      description: drift.Value(description?.trim().isEmpty ?? true ? null : description!.trim()),
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(DateTime.now()),
    ));
  }

  Future<int> deletePayment(String id) => _db.deletePayment(id);

  Future<int> markPaymentReceived(String id) => _db.updatePaymentStatus(id, 'RECEIVED');

  // --- Freelance Project Creation ---
  Future<String> createFreelanceProject({
    required String name,
    String? description,
    String? clientId,
    String? leadId,
    double progress = 0.0,
    String? techStack,
    DateTime? deadline,
    String? notes,
    String status = 'in_progress',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.insertProject(ProjectsCompanion(
      id: drift.Value(id),
      name: drift.Value(name.trim()),
      description: drift.Value(description?.trim().isEmpty ?? true ? null : description!.trim()),
      status: drift.Value(status),
      progress: drift.Value(progress),
      techStack: drift.Value(techStack?.trim().isEmpty ?? true ? null : techStack!.trim()),
      deadline: drift.Value(deadline),
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes!.trim()),
      clientId: drift.Value(clientId),
      leadId: drift.Value(leadId),
      isFreelance: const drift.Value(true),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    ));

    // If a lead was associated, link this project to the lead
    if (leadId != null) {
      final lead = await _db.getLeadById(leadId);
      if (lead != null) {
        await _db.updateLead(lead.toCompanion(true).copyWith(
          projectId: drift.Value(id),
          updatedAt: drift.Value(now),
        ));
      }
    }

    return id;
  }
}

// Global Provider for FreelanceRepository
final freelanceRepositoryProvider = Provider<FreelanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FreelanceRepository(db);
});

