class RoleFamily {
  // Engineering
  static const mobile = 'MOBILE';
  static const frontend = 'FRONTEND';
  static const backend = 'BACKEND';
  static const fullstack = 'FULLSTACK';
  static const dataEngineering = 'DATA_ENGINEERING';
  static const dataScienceMl = 'DATA_SCIENCE_ML';
  static const aiEngineering = 'AI_ENGINEERING';
  static const devopsSrePlatform = 'DEVOPS_SRE_PLATFORM';
  static const qaTest = 'QA_TEST';
  static const security = 'SECURITY';
  static const embeddedFirmware = 'EMBEDDED_FIRMWARE';
  static const game = 'GAME';
  static const engineeringManagement = 'ENGINEERING_MANAGEMENT';

  // Other technical
  static const salesEngineeringPresales = 'SALES_ENGINEERING_PRESALES';
  static const solutionsConsulting = 'SOLUTIONS_CONSULTING';
  static const productManagement = 'PRODUCT_MANAGEMENT';
  static const design = 'DESIGN';
  static const technicalWriting = 'TECHNICAL_WRITING';
  static const itSupportAdmin = 'IT_SUPPORT_ADMIN';
  static const dataAnalystBi = 'DATA_ANALYST_BI';

  // Non-technical
  static const dataEntryAnnotation = 'DATA_ENTRY_ANNOTATION';
  static const sales = 'SALES';
  static const businessDevelopment = 'BUSINESS_DEVELOPMENT';
  static const marketing = 'MARKETING';
  static const hrRecruiting = 'HR_RECRUITING';
  static const financeAccounting = 'FINANCE_ACCOUNTING';
  static const operations = 'OPERATIONS';
  static const customerSupport = 'CUSTOMER_SUPPORT';
  static const civil = 'CIVIL';
  static const mechanical = 'MECHANICAL';
  static const electrical = 'ELECTRICAL';
  static const teachingTraining = 'TEACHING_TRAINING';
  static const healthcare = 'HEALTHCARE';
  static const legal = 'LEGAL';
  static const other = 'OTHER';
  static const unknown = 'UNKNOWN';

  static const Set<String> nonEngineering = {
    dataEntryAnnotation, sales, businessDevelopment, marketing, hrRecruiting,
    financeAccounting, operations, customerSupport, civil, mechanical,
    electrical, teachingTraining, healthcare, legal, other,
  };
}

class RoleClassifier {
  RoleClassifier._();

  static bool isEngineeringRole(String family) => !RoleFamily.nonEngineering.contains(family);

  /// Classifies a job posting into its role family based on title rules, tech hints, and responsibilities.
  /// Anti-random-job guarantee: A title classified into a non-engineering family can NEVER be moved
  /// into an engineering family by description keywords.
  static String classify({
    required String title,
    String? description,
  }) {
    final lowerTitle = title.toLowerCase().trim();

    // 1. NON-TECHNICAL / NON-ENGINEERING PATTERNS (MUST WIN OVER GENERIC WORDS)
    if (RegExp(r'\b(ai\s+trainer|data\s+annotation|annotator|annotation|data\s+entry|data\s+labeler|labeling)\b').hasMatch(lowerTitle)) {
      return RoleFamily.dataEntryAnnotation;
    }
    if (RegExp(r'\b(business\s+development|bde|bdr)\b').hasMatch(lowerTitle)) {
      return RoleFamily.businessDevelopment;
    }
    if (RegExp(r'\b(account\s+executive|sales\s+manager|sales\s+director|sales\s+representative|sales\s+rep|inside\s+sales|vp\s+of\s+sales|head\s+of\s+sales)\b').hasMatch(lowerTitle)) {
      return RoleFamily.sales;
    }
    if (RegExp(r'\b(sales\s+engineer|presales|pre-sales|solutions\s+engineer)\b').hasMatch(lowerTitle)) {
      return RoleFamily.salesEngineeringPresales;
    }
    if (RegExp(r'\b(solutions\s+consultant|solutions\s+architect)\b').hasMatch(lowerTitle)) {
      return RoleFamily.solutionsConsulting;
    }
    if (RegExp(r'\b(hr\s+executive|hr\s+manager|recruiter|talent\s+acquisition|people\s+partner|human\s+resources|recruiting)\b').hasMatch(lowerTitle)) {
      return RoleFamily.hrRecruiting;
    }
    if (RegExp(r'\b(accountant|accounting|finance|chartered\s+accountant|tally|bookkeeper|audit|financial\s+analyst)\b').hasMatch(lowerTitle)) {
      return RoleFamily.financeAccounting;
    }
    if (RegExp(r'\b(civil\s+engineer|civil\s+design|autocad\s+civil|structural\s+engineer)\b').hasMatch(lowerTitle)) {
      return RoleFamily.civil;
    }
    if (RegExp(r'\b(mechanical\s+engineer|mechanical\s+design|cad\s+designer|hvac)\b').hasMatch(lowerTitle)) {
      return RoleFamily.mechanical;
    }
    if (RegExp(r'\b(electrical\s+engineer|electronics\s+engineer|pcb\s+(layout\s+)?designer|hardware\s+engineer)\b').hasMatch(lowerTitle)) {
      return RoleFamily.electrical;
    }
    if (RegExp(r'\b(instructor|trainer|teacher|teaching|professor|faculty|tutor|mentor)\b').hasMatch(lowerTitle)) {
      return RoleFamily.teachingTraining;
    }
    if (RegExp(r'\b(it\s+support|system\s+administrator|sysadmin|desktop\s+support|network\s+admin)\b').hasMatch(lowerTitle)) {
      return RoleFamily.itSupportAdmin;
    }
    if (RegExp(r'\b(customer\s+support|customer\s+success|client\s+support|helpdesk|support\s+specialist)\b').hasMatch(lowerTitle)) {
      return RoleFamily.customerSupport;
    }
    if (RegExp(r'\b(marketing|seo|growth|content\s+writer|copywriter|social\s+media)\b').hasMatch(lowerTitle)) {
      return RoleFamily.marketing;
    }
    if (RegExp(r'\b(product\s+manager|technical\s+product\s+manager|pm|group\s+pm)\b').hasMatch(lowerTitle)) {
      return RoleFamily.productManagement;
    }
    if (RegExp(r'\b(ui\/ux|product\s+designer|graphic\s+designer|ux\s+designer|ui\s+designer)\b').hasMatch(lowerTitle)) {
      return RoleFamily.design;
    }
    if (RegExp(r'\b(technical\s+writer|documentation\s+engineer)\b').hasMatch(lowerTitle)) {
      return RoleFamily.technicalWriting;
    }
    if (RegExp(r'\b(data\s+analyst|bi\s+analyst|business\s+analyst|tableau|power\s+bi)\b').hasMatch(lowerTitle)) {
      return RoleFamily.dataAnalystBi;
    }

    // 2. ENGINEERING MANAGEMENT
    if (RegExp(r'\b(engineering\s+manager|director\s+of\s+engineering|vp\s+of\s+engineering|head\s+of\s+engineering|tech\s+lead\s+manager)\b').hasMatch(lowerTitle)) {
      return RoleFamily.engineeringManagement;
    }

    // 3. SPECIALIZED ENGINEERING DISCIPLINES (Evaluate before general platform terms)
    // QA / Test (e.g. SDET - Mobile must be QA_TEST, not MOBILE)
    if (RegExp(r'\b(qa|sdet|test\s+engineer|quality\s+assurance|automation\s+engineer|tester)\b').hasMatch(lowerTitle)) {
      return RoleFamily.qaTest;
    }

    // Security
    if (RegExp(r'\b(security\s+engineer|cyber\s+security|infosec|appsec)\b').hasMatch(lowerTitle)) {
      return RoleFamily.security;
    }

    // Embedded / Firmware / Game
    if (RegExp(r'\b(embedded|firmware|iot|rtos)\b').hasMatch(lowerTitle)) {
      return RoleFamily.embeddedFirmware;
    }
    if (RegExp(r'\b(game\s+developer|unity|unreal)\b').hasMatch(lowerTitle)) {
      return RoleFamily.game;
    }

    // Data Engineering
    if (RegExp(r'\b(data\s+engineer|big\s+data|etl|spark|hadoop|data\s+pipeline)\b').hasMatch(lowerTitle)) {
      return RoleFamily.dataEngineering;
    }

    // Data Science & ML / AI
    if (RegExp(r'\b(machine\s+learning|ml\s+engineer|data\s+scientist|deep\s+learning)\b').hasMatch(lowerTitle)) {
      return RoleFamily.dataScienceMl;
    }
    if (RegExp(r'\b(ai\s+engineer|llm\s+engineer|generative\s+ai)\b').hasMatch(lowerTitle)) {
      return RoleFamily.aiEngineering;
    }

    // DevOps / SRE / Cloud
    if (RegExp(r'\b(devops|sre|site\s+reliability|platform\s+engineer|cloud\s+engineer|infrastructure|kubernetes)\b').hasMatch(lowerTitle)) {
      return RoleFamily.devopsSrePlatform;
    }

    // 4. PLATFORM & GENERAL SOFTWARE ROLES
    // Mobile
    if (RegExp(r'\b(flutter|react\s+native|ios|android|mobile|swiftui|jetpack\s+compose)\b').hasMatch(lowerTitle)) {
      return RoleFamily.mobile;
    }

    // Full Stack
    if (RegExp(r'\b(full[\s-]?stack|fullstack)\b').hasMatch(lowerTitle)) {
      return RoleFamily.fullstack;
    }

    // Frontend
    if (RegExp(r'\b(frontend|front[\s-]?end|react|angular|vue|svelte|web\s+developer|ui\s+developer)\b').hasMatch(lowerTitle)) {
      return RoleFamily.frontend;
    }

    // Backend
    if (lowerTitle.contains('c#') ||
        lowerTitle.contains('.net') ||
        RegExp(r'\b(backend|back[\s-]?end|java|golang|go\s+developer|python\s+developer|node|django|spring\s+boot|csharp|dotnet|ruby|rails)\b').hasMatch(lowerTitle)) {
      return RoleFamily.backend;
    }

    // 4. Fallback on description ONLY if title was ambiguous ("Engineer", "Software Engineer", "Consultant", "Associate")
    if (description != null && description.isNotEmpty && RegExp(r'\b(engineer|developer|programmer|consultant|associate)\b').hasMatch(lowerTitle)) {
      final descSnippet = description.length > 1500 ? description.substring(0, 1500).toLowerCase() : description.toLowerCase();
      if (descSnippet.contains('flutter') || descSnippet.contains('react native') || descSnippet.contains('mobile app')) {
        return RoleFamily.mobile;
      }
      if (descSnippet.contains('full stack') || descSnippet.contains('fullstack')) {
        return RoleFamily.fullstack;
      }
      if (descSnippet.contains('frontend') || descSnippet.contains('front-end')) {
        return RoleFamily.frontend;
      }
      if (descSnippet.contains('backend') || descSnippet.contains('back-end') || descSnippet.contains('api development')) {
        return RoleFamily.backend;
      }
    }

    if (RegExp(r'\b(software\s+engineer|software\s+developer|sde|member\s+of\s+technical\s+staff)\b').hasMatch(lowerTitle)) {
      return RoleFamily.backend; // Standard default for general SDE
    }

    return RoleFamily.unknown;
  }
}
