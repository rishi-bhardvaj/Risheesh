enum JobFreshness {
  newJob,
  updated,
  recent,
  old,
}

class FreshnessEvaluator {
  FreshnessEvaluator._();

  static JobFreshness evaluate({
    required DateTime firstSeenAt,
    DateTime? lastUpdatedAt,
    DateTime? postedAt,
    DateTime? seenAt,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now().toUtc();

    // 1. NEW: firstSeenAt within 24h and not yet seen
    if (seenAt == null && effectiveNow.difference(firstSeenAt).inHours <= 24) {
      return JobFreshness.newJob;
    }

    // 2. UPDATED: lastUpdatedAt within 48 hours and after firstSeenAt + 1 hour
    if (lastUpdatedAt != null &&
        effectiveNow.difference(lastUpdatedAt).inHours <= 48 &&
        lastUpdatedAt.difference(firstSeenAt).inHours >= 1) {
      return JobFreshness.updated;
    }

    // 3. RECENT: postedAt or firstSeenAt within 7 days
    final refDate = postedAt ?? firstSeenAt;
    if (effectiveNow.difference(refDate).inDays <= 7) {
      return JobFreshness.recent;
    }

    return JobFreshness.old;
  }
}
