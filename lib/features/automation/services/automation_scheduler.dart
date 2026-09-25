import 'dart:async';
import 'package:flutter/foundation.dart';
import 'automation_engine.dart';

class AutomationScheduler {
  final AutomationEngine engine;
  Timer? _periodicTimer;
  bool _isRunning = false;

  AutomationScheduler({required this.engine});

  bool get isRunning => _isRunning;

  void start({Duration interval = const Duration(minutes: 60)}) {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('[AutomationScheduler] Started with interval: ${interval.inMinutes} minutes');

    // Run immediately once
    _runSchedulerCycle();

    _periodicTimer = Timer.periodic(interval, (_) {
      _runSchedulerCycle();
    });
  }

  Future<void> _runSchedulerCycle() async {
    try {
      debugPrint('[AutomationScheduler] Running periodic automation cycle...');
      await engine.runAllEnabledRules();
      debugPrint('[AutomationScheduler] Cycle completed successfully');
    } catch (e) {
      debugPrint('[AutomationScheduler] Error in cycle: $e');
    }
  }

  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isRunning = false;
    debugPrint('[AutomationScheduler] Stopped');
  }
}
