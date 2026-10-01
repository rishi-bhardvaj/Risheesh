import 'package:test/test.dart';
import 'package:career_core/career_core.dart';

void main() {
  group('Role Classifier Tests (M5)', () {
    final titleTestCases = <(String, String)>[
      // Traps & non-engineering roles
      ('Software Sales Manager', RoleFamily.sales),
      ('Enterprise Sales Representative', RoleFamily.sales),
      ('Inside Sales Executive', RoleFamily.sales),
      ('Sales Engineer', RoleFamily.salesEngineeringPresales),
      ('Presales Technical Consultant', RoleFamily.salesEngineeringPresales),
      ('Solutions Consultant', RoleFamily.solutionsConsulting),
      ('Data Entry Operator', RoleFamily.dataEntryAnnotation),
      ('AI Trainer – Python', RoleFamily.dataEntryAnnotation),
      ('Data Annotation Specialist', RoleFamily.dataEntryAnnotation),
      ('Business Development Executive – SaaS', RoleFamily.businessDevelopment),
      ('Senior BDR - Tech', RoleFamily.businessDevelopment),
      ('Civil Engineer – AutoCAD', RoleFamily.civil),
      ('Structural Civil Engineer', RoleFamily.civil),
      ('Mechanical Design Engineer', RoleFamily.mechanical),
      ('HVAC Mechanical Engineer', RoleFamily.mechanical),
      ('Electrical Engineer - Hardware', RoleFamily.electrical),
      ('PCB Layout Designer', RoleFamily.electrical),
      ('Accountant (Tally, Excel, data)', RoleFamily.financeAccounting),
      ('Financial Analyst / Audit', RoleFamily.financeAccounting),
      ('HR Executive (HRMS, Python basics)', RoleFamily.hrRecruiting),
      ('Senior Technical Recruiter', RoleFamily.hrRecruiting),
      ('Customer Support Specialist', RoleFamily.customerSupport),
      ('Client Support Helpdesk', RoleFamily.customerSupport),
      ('Python Instructor', RoleFamily.teachingTraining),
      ('Coding Bootcamp Mentor', RoleFamily.teachingTraining),
      ('Technical Product Manager', RoleFamily.productManagement),
      ('Group PM - Core Platform', RoleFamily.productManagement),
      ('UI/UX Designer', RoleFamily.design),
      ('Lead Product Designer', RoleFamily.design),
      ('Technical Writer (API Documentation)', RoleFamily.technicalWriting),
      ('IT Support Specialist', RoleFamily.itSupportAdmin),
      ('Desktop Support Sysadmin', RoleFamily.itSupportAdmin),
      ('Data Analyst (Tableau / SQL)', RoleFamily.dataAnalystBi),
      ('Power BI Business Analyst', RoleFamily.dataAnalystBi),

      // Engineering Management
      ('Engineering Manager - Mobile', RoleFamily.engineeringManagement),
      ('Director of Engineering', RoleFamily.engineeringManagement),
      ('VP of Engineering', RoleFamily.engineeringManagement),

      // Mobile
      ('Flutter Developer', RoleFamily.mobile),
      ('Senior Flutter Engineer', RoleFamily.mobile),
      ('iOS Engineer (Swift/SwiftUI)', RoleFamily.mobile),
      ('Android Developer (Kotlin/Compose)', RoleFamily.mobile),
      ('React Native Engineer', RoleFamily.mobile),

      // Frontend
      ('Frontend Engineer', RoleFamily.frontend),
      ('Senior React Developer', RoleFamily.frontend),
      ('Vue.js Web Developer', RoleFamily.frontend),
      ('Angular Frontend Specialist', RoleFamily.frontend),
      ('UI Developer', RoleFamily.frontend),

      // Backend
      ('Java Developer', RoleFamily.backend),
      ('Senior Backend Engineer (Go)', RoleFamily.backend),
      ('Python Backend Engineer', RoleFamily.backend),
      ('Node.js API Engineer', RoleFamily.backend),
      ('C# / .NET Core Developer', RoleFamily.backend),
      ('Ruby on Rails Developer', RoleFamily.backend),
      ('Software Engineer', RoleFamily.backend),

      // Full Stack
      ('Full Stack Developer', RoleFamily.fullstack),
      ('Fullstack Engineer (React/Node)', RoleFamily.fullstack),
      ('Full-Stack Software Engineer', RoleFamily.fullstack),

      // DevOps / Cloud / SRE
      ('DevOps Engineer', RoleFamily.devopsSrePlatform),
      ('Site Reliability Engineer (SRE)', RoleFamily.devopsSrePlatform),
      ('Cloud Platform Engineer', RoleFamily.devopsSrePlatform),

      // Data Engineering / Science / ML
      ('Data Engineer (Spark/ETL)', RoleFamily.dataEngineering),
      ('Machine Learning Engineer', RoleFamily.dataScienceMl),
      ('Data Scientist', RoleFamily.dataScienceMl),
      ('Generative AI Engineer', RoleFamily.aiEngineering),

      // QA / Test
      ('QA Automation Engineer', RoleFamily.qaTest),
      ('SDET - Mobile', RoleFamily.qaTest),

      // Security & Embedded
      ('Security Engineer (AppSec)', RoleFamily.security),
      ('Embedded Firmware Engineer', RoleFamily.embeddedFirmware),
      ('Unity Game Developer', RoleFamily.game),

      // Ambiguous
      ('Associate', RoleFamily.unknown),
    ];

    test('Table-driven verification of 60+ titles', () {
      expect(titleTestCases.length, greaterThanOrEqualTo(60));
      for (final tc in titleTestCases) {
        final family = RoleClassifier.classify(title: tc.$1);
        expect(
          family,
          equals(tc.$2),
          reason: 'Title "${tc.$1}" should classify as ${tc.$2}, got $family',
        );
      }
    });

    test('Description keywords NEVER move non-engineering title into engineering', () {
      const title = 'Software Sales Manager';
      const description = 'Looking for an experienced software sales leader with deep knowledge of Python, Java, Flutter, AWS, and Cloud Architecture.';
      final family = RoleClassifier.classify(title: title, description: description);
      expect(family, equals(RoleFamily.sales));
    });
  });
}
