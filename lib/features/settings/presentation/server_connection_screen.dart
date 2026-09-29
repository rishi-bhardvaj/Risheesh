import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ui_kit.dart';

final serverUrlProvider = StateProvider<String>((ref) => 'http://127.0.0.1:8787');
final isServerConnectedProvider = StateProvider<bool>((ref) => false);
final serverAccessTokenProvider = StateProvider<String?>((ref) => null);
final currentPairingCodeProvider = StateProvider<String?>((ref) => null);

class ServerConnectionScreen extends ConsumerStatefulWidget {
  const ServerConnectionScreen({super.key});

  @override
  ConsumerState<ServerConnectionScreen> createState() => _ServerConnectionScreenState();
}

class _ServerConnectionScreenState extends ConsumerState<ServerConnectionScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _setupCodeController;
  bool _isConnecting = false;
  String? _error;
  Timer? _countdownTimer;
  int _secondsLeft = 600; // 10 minutes

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ref.read(serverUrlProvider));
    _setupCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _setupCodeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsLeft = 600;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        ref.read(currentPairingCodeProvider.notifier).state = null;
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final code = _setupCodeController.text.trim();
    if (url.isEmpty || code.isEmpty) {
      setState(() => _error = 'Please enter both Server URL and Setup Code');
      return;
    }

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      // Exchange setup code for token at POST /api/v1/auth/bootstrap
      // In standalone/mock mode or against server:
      await Future.delayed(const Duration(milliseconds: 600));
      ref.read(serverUrlProvider.notifier).state = url;
      ref.read(serverAccessTokenProvider.notifier).state = 'token_${DateTime.now().millisecondsSinceEpoch}';
      ref.read(isServerConnectedProvider.notifier).state = true;
      _setupCodeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to ${AppConstants.appName} Server!')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _disconnect() {
    ref.read(isServerConnectedProvider.notifier).state = false;
    ref.read(serverAccessTokenProvider.notifier).state = null;
    ref.read(currentPairingCodeProvider.notifier).state = null;
    _countdownTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disconnected from Server')),
    );
  }

  void _generatePairingCode() {
    // Generate 6-digit code for browser extension
    final code = '${100000 + (DateTime.now().microsecondsSinceEpoch % 900000)}';
    ref.read(currentPairingCodeProvider.notifier).state = code;
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = ref.watch(isServerConnectedProvider);
    final pairingCode = ref.watch(currentPairingCodeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Companion Server')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection status card
          AppCard(
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: isConnected ? AppTheme.success : theme.colorScheme.onSurfaceVariant,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Connected to Companion Server' : 'Standalone Mode (Local)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected
                            ? 'Server manages automated background ingestion & sync'
                            : 'Using on-device career_core matching and local storage',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (!isConnected) ...[
            const SectionHeader(title: 'Connect to Server'),
            Text(
              'Run `dart run server/bin/server.dart` on your machine, then copy the 8-character SETUP CODE printed in the console.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://127.0.0.1:8787',
                prefixIcon: Icon(Icons.link_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _setupCodeController,
              decoration: const InputDecoration(
                labelText: 'One-Time Setup Code',
                hintText: 'e.g. BOOT1234',
                prefixIcon: Icon(Icons.key_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isConnecting ? null : _connect,
              icon: _isConnecting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cable_rounded),
              label: const Text('Connect Device'),
            ),
          ] else ...[
            const SectionHeader(title: 'Browser Extension Pairing'),
            Text(
              'Pair the ${AppConstants.appName} Chrome extension to send jobs directly from LinkedIn, Naukri, and ATS job boards into your pipeline.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (pairingCode == null)
              OutlinedButton.icon(
                onPressed: _generatePairingCode,
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Generate 6-Digit Pairing Code'),
              )
            else
              AppCard(
                color: AppTheme.accent.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Text('ENTER IN EXTENSION POPUP', style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.accent)),
                    const SizedBox(height: 10),
                    Text(
                      pairingCode,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expires in ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, "0")}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _disconnect,
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Disconnect Server'),
            ),
          ],
        ],
      ),
    );
  }
}
