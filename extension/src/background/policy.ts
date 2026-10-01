export interface ExtensionPlatformPolicy {
  autoRefreshAllowed: boolean;
  domExtractionAllowed: boolean;
  userCaptureAllowed: boolean;
}

export class PolicyGate {
  private static defaultPolicies: Record<string, ExtensionPlatformPolicy> = {
    linkedin: {
      autoRefreshAllowed: false,
      domExtractionAllowed: false,
      userCaptureAllowed: true,
    },
    naukri: {
      autoRefreshAllowed: false,
      domExtractionAllowed: false,
      userCaptureAllowed: true,
    },
    ats: {
      autoRefreshAllowed: true,
      domExtractionAllowed: true,
      userCaptureAllowed: true,
    },
    web: {
      autoRefreshAllowed: false,
      domExtractionAllowed: true,
      userCaptureAllowed: true,
    },
  };

  static isAutoRefreshPermitted(platform: string): boolean {
    return this.defaultPolicies[platform]?.autoRefreshAllowed ?? false;
  }

  static isDomExtractionPermitted(platform: string): boolean {
    return this.defaultPolicies[platform]?.domExtractionAllowed ?? false;
  }

  static isUserCapturePermitted(platform: string): boolean {
    return this.defaultPolicies[platform]?.userCaptureAllowed ?? true;
  }
}
