enum CapabilityState {
  supported,
  assisted,
  unsupported,
}

class PlatformPolicyRule {
  final String platformId;
  final bool autoDomExtraction;
  final bool autoPageRefresh;
  final bool userInitiatedCapture;
  final CapabilityState profileAutomation;
  final String termsReference;

  const PlatformPolicyRule({
    required this.platformId,
    required this.autoDomExtraction,
    required this.autoPageRefresh,
    required this.userInitiatedCapture,
    required this.profileAutomation,
    required this.termsReference,
  });
}

class PlatformPolicy {
  PlatformPolicy._();

  static const Map<String, PlatformPolicyRule> rules = {
    'linkedin': PlatformPolicyRule(
      platformId: 'linkedin',
      autoDomExtraction: false,
      autoPageRefresh: false,
      userInitiatedCapture: true,
      profileAutomation: CapabilityState.assisted,
      termsReference: 'LinkedIn User Agreement Section 8.2 (prohibits scraping bots and browser plugins)',
    ),
    'naukri': PlatformPolicyRule(
      platformId: 'naukri',
      autoDomExtraction: false,
      autoPageRefresh: false,
      userInitiatedCapture: true,
      profileAutomation: CapabilityState.assisted,
      termsReference: 'Naukri Terms of Use (prohibits unauthorized scraping and automated tools)',
    ),
    'greenhouse': PlatformPolicyRule(
      platformId: 'greenhouse',
      autoDomExtraction: true,
      autoPageRefresh: true,
      userInitiatedCapture: true,
      profileAutomation: CapabilityState.unsupported,
      termsReference: 'Public Greenhouse Job Board API documentation',
    ),
    'lever': PlatformPolicyRule(
      platformId: 'lever',
      autoDomExtraction: true,
      autoPageRefresh: true,
      userInitiatedCapture: true,
      profileAutomation: CapabilityState.unsupported,
      termsReference: 'Public Lever Postings API documentation',
    ),
    'ashby': PlatformPolicyRule(
      platformId: 'ashby',
      autoDomExtraction: true,
      autoPageRefresh: true,
      userInitiatedCapture: true,
      profileAutomation: CapabilityState.unsupported,
      termsReference: 'Public Ashby Careers API documentation',
    ),
  };

  static bool isAutoRefreshPermitted(String platformId) =>
      rules[platformId.toLowerCase()]?.autoPageRefresh ?? false;

  static CapabilityState getProfileAutomationCapability(String platformId) =>
      rules[platformId.toLowerCase()]?.profileAutomation ?? CapabilityState.unsupported;
}
