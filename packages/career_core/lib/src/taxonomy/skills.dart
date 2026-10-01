enum SkillCategory {
  language,
  framework,
  library,
  database,
  cloud,
  devops,
  frontend,
  backend,
  mobile,
  ai_ml,
  data,
  testing,
  tool,
}

enum SkillKind {
  core, // Language, framework or platform
  supporting, // Tool, library or secondary skill
}

class SkillDefinition {
  final String canonical;
  final SkillCategory category;
  final SkillKind kind;
  final List<String> aliases;
  final Map<String, double> related;
  final List<String> implies;

  const SkillDefinition({
    required this.canonical,
    required this.category,
    this.kind = SkillKind.core,
    this.aliases = const [],
    this.related = const {},
    this.implies = const [],
  });
}

class SkillTaxonomy {
  SkillTaxonomy._();

  static final Map<String, SkillDefinition> _skills = {};
  static final Map<String, String> _aliasToCanonical = {};

  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _initialized = true;

    void add(SkillDefinition s) {
      _skills[s.canonical.toLowerCase()] = s;
      _aliasToCanonical[s.canonical.toLowerCase()] = s.canonical;
      for (final a in s.aliases) {
        _aliasToCanonical[a.toLowerCase()] = s.canonical;
      }
    }

    // 1. Languages
    add(const SkillDefinition(
      canonical: 'Dart',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['dartlang'],
      related: {'Flutter': 0.9, 'JavaScript': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'JavaScript',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['js', 'ecmascript', 'es6', 'es2015', 'es2020'],
      related: {'TypeScript': 0.8},
    ));
    add(const SkillDefinition(
      canonical: 'TypeScript',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['ts'],
      implies: ['JavaScript'],
      related: {'JavaScript': 0.9},
    ));
    add(const SkillDefinition(
      canonical: 'Python',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['python3', 'py'],
    ));
    add(const SkillDefinition(
      canonical: 'Java',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['java8', 'java11', 'java17', 'java21', 'core java'],
      related: {'Kotlin': 0.5, 'Scala': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'Kotlin',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['kt'],
      related: {'Java': 0.5, 'Android': 0.7},
    ));
    add(const SkillDefinition(
      canonical: 'Swift',
      category: SkillCategory.language,
      kind: SkillKind.core,
      related: {'iOS': 0.8, 'Objective-C': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'Go',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['golang'],
    ));
    add(const SkillDefinition(
      canonical: 'Rust',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['rustlang'],
    ));
    add(const SkillDefinition(
      canonical: 'C++',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['cpp', 'cplusplus'],
      related: {'C': 0.5},
    ));
    add(const SkillDefinition(
      canonical: 'C#',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['csharp', 'c-sharp', 'cs'],
      related: {'.NET': 0.9},
    ));
    add(const SkillDefinition(
      canonical: 'C',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['clang'],
      related: {'C++': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'PHP',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['php7', 'php8'],
      related: {'Laravel': 0.7},
    ));
    add(const SkillDefinition(
      canonical: 'Ruby',
      category: SkillCategory.language,
      kind: SkillKind.core,
      related: {'Rails': 0.8},
    ));
    add(const SkillDefinition(
      canonical: 'Scala',
      category: SkillCategory.language,
      kind: SkillKind.core,
      related: {'Java': 0.5},
    ));
    add(const SkillDefinition(
      canonical: 'SQL',
      category: SkillCategory.language,
      kind: SkillKind.supporting,
      aliases: ['ansi sql', 'structured query language'],
    ));
    add(const SkillDefinition(
      canonical: 'HTML',
      category: SkillCategory.language,
      kind: SkillKind.supporting,
      aliases: ['html5'],
    ));
    add(const SkillDefinition(
      canonical: 'CSS',
      category: SkillCategory.language,
      kind: SkillKind.supporting,
      aliases: ['css3'],
    ));
    add(const SkillDefinition(
      canonical: 'Bash',
      category: SkillCategory.language,
      kind: SkillKind.supporting,
      aliases: ['sh', 'shell', 'shell script', 'shell scripting'],
    ));
    add(const SkillDefinition(
      canonical: 'R',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['rlang'],
    ));
    add(const SkillDefinition(
      canonical: 'MATLAB',
      category: SkillCategory.language,
      kind: SkillKind.supporting,
    ));
    add(const SkillDefinition(
      canonical: 'Objective-C',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['objc'],
      related: {'Swift': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'Solidity',
      category: SkillCategory.language,
      kind: SkillKind.core,
      aliases: ['smart contracts'],
    ));
    add(const SkillDefinition(
      canonical: 'Elixir',
      category: SkillCategory.language,
      kind: SkillKind.core,
      related: {'Erlang': 0.6},
    ));
    add(const SkillDefinition(
      canonical: 'Haskell',
      category: SkillCategory.language,
      kind: SkillKind.core,
    ));

    // 2. Frameworks & Platforms (Mobile / Frontend / Backend)
    add(const SkillDefinition(
      canonical: 'Flutter',
      category: SkillCategory.mobile,
      kind: SkillKind.core,
      aliases: ['flutter framework', 'flutter sdk'],
      implies: ['Dart'],
      related: {'React Native': 0.3, 'Android': 0.4, 'iOS': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'React Native',
      category: SkillCategory.mobile,
      kind: SkillKind.core,
      aliases: ['react-native'],
      implies: ['React', 'JavaScript'],
      related: {'Flutter': 0.3, 'React': 0.8},
    ));
    add(const SkillDefinition(
      canonical: 'Android',
      category: SkillCategory.mobile,
      kind: SkillKind.core,
      aliases: ['android sdk', 'android app development'],
      related: {'Kotlin': 0.6, 'Java': 0.5},
    ));
    add(const SkillDefinition(
      canonical: 'iOS',
      category: SkillCategory.mobile,
      kind: SkillKind.core,
      aliases: ['ios development', 'ios sdk'],
      related: {'Swift': 0.7},
    ));
    add(const SkillDefinition(
      canonical: 'Jetpack Compose',
      category: SkillCategory.mobile,
      kind: SkillKind.core,
      implies: ['Kotlin', 'Android'],
    ));
    add(const SkillDefinition(
      canonical: 'SwiftUI',
      category: SkillCategory.mobile,
      kind: SkillKind.core,
      implies: ['Swift', 'iOS'],
    ));
    add(const SkillDefinition(
      canonical: 'React',
      category: SkillCategory.frontend,
      kind: SkillKind.core,
      aliases: ['reactjs', 'react.js', 'react js'],
      implies: ['JavaScript'],
      related: {'Next.js': 0.7},
    ));
    add(const SkillDefinition(
      canonical: 'Next.js',
      category: SkillCategory.frontend,
      kind: SkillKind.core,
      aliases: ['nextjs', 'next'],
      implies: ['React', 'JavaScript'],
    ));
    add(const SkillDefinition(
      canonical: 'Vue.js',
      category: SkillCategory.frontend,
      kind: SkillKind.core,
      aliases: ['vue', 'vuejs', 'vue 3'],
      implies: ['JavaScript'],
    ));
    add(const SkillDefinition(
      canonical: 'Nuxt',
      category: SkillCategory.frontend,
      kind: SkillKind.core,
      aliases: ['nuxtjs'],
      implies: ['Vue.js', 'JavaScript'],
    ));
    add(const SkillDefinition(
      canonical: 'Angular',
      category: SkillCategory.frontend,
      kind: SkillKind.core,
      aliases: ['angularjs', 'angular2+', 'angular 2+'],
      implies: ['TypeScript', 'JavaScript'],
    ));
    add(const SkillDefinition(
      canonical: 'Svelte',
      category: SkillCategory.frontend,
      kind: SkillKind.core,
      aliases: ['sveltejs', 'sveltekit'],
      implies: ['JavaScript'],
    ));
    add(const SkillDefinition(
      canonical: 'Node.js',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      aliases: ['node', 'nodejs'],
      implies: ['JavaScript'],
    ));
    add(const SkillDefinition(
      canonical: 'Express',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      aliases: ['expressjs', 'express.js'],
      implies: ['Node.js'],
    ));
    add(const SkillDefinition(
      canonical: 'NestJS',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      aliases: ['nest.js', 'nest js'],
      implies: ['Node.js', 'TypeScript'],
    ));
    add(const SkillDefinition(
      canonical: 'Spring',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      aliases: ['spring framework'],
      implies: ['Java'],
      related: {'Spring Boot': 0.7},
    ));
    add(const SkillDefinition(
      canonical: 'Spring Boot',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      aliases: ['springboot'],
      implies: ['Spring', 'Java'],
      related: {'Spring': 0.7},
    ));
    add(const SkillDefinition(
      canonical: 'Django',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      implies: ['Python'],
    ));
    add(const SkillDefinition(
      canonical: 'FastAPI',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      implies: ['Python'],
    ));
    add(const SkillDefinition(
      canonical: 'Flask',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      implies: ['Python'],
    ));
    add(const SkillDefinition(
      canonical: '.NET',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      aliases: ['dotnet', '.net core', 'asp.net', 'asp.net core'],
      related: {'C#': 0.9},
    ));
    add(const SkillDefinition(
      canonical: 'Laravel',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      implies: ['PHP'],
    ));
    add(const SkillDefinition(
      canonical: 'Rails',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      aliases: ['ruby on rails'],
      implies: ['Ruby'],
    ));
    add(const SkillDefinition(
      canonical: 'Riverpod',
      category: SkillCategory.mobile,
      kind: SkillKind.supporting,
      implies: ['Flutter', 'Dart'],
    ));
    add(const SkillDefinition(
      canonical: 'Bloc',
      category: SkillCategory.mobile,
      kind: SkillKind.supporting,
      implies: ['Flutter', 'Dart'],
    ));
    add(const SkillDefinition(
      canonical: 'Provider',
      category: SkillCategory.mobile,
      kind: SkillKind.supporting,
      implies: ['Flutter', 'Dart'],
    ));

    // 3. Databases
    add(const SkillDefinition(
      canonical: 'PostgreSQL',
      category: SkillCategory.database,
      kind: SkillKind.core,
      aliases: ['postgres', 'pgsql'],
      implies: ['SQL'],
      related: {'MySQL': 0.5},
    ));
    add(const SkillDefinition(
      canonical: 'MySQL',
      category: SkillCategory.database,
      kind: SkillKind.core,
      implies: ['SQL'],
      related: {'PostgreSQL': 0.5, 'MariaDB': 0.8},
    ));
    add(const SkillDefinition(
      canonical: 'MongoDB',
      category: SkillCategory.database,
      kind: SkillKind.core,
      aliases: ['mongo'],
    ));
    add(const SkillDefinition(
      canonical: 'Redis',
      category: SkillCategory.database,
      kind: SkillKind.core,
    ));
    add(const SkillDefinition(
      canonical: 'SQLite',
      category: SkillCategory.database,
      kind: SkillKind.core,
      implies: ['SQL'],
      aliases: ['sqlite3'],
    ));
    add(const SkillDefinition(
      canonical: 'Drift',
      category: SkillCategory.database,
      kind: SkillKind.supporting,
      implies: ['SQLite', 'Dart'],
    ));
    add(const SkillDefinition(
      canonical: 'Firebase',
      category: SkillCategory.cloud,
      kind: SkillKind.core,
      aliases: ['firestore', 'firebase auth'],
    ));
    add(const SkillDefinition(
      canonical: 'Supabase',
      category: SkillCategory.cloud,
      kind: SkillKind.core,
      implies: ['PostgreSQL'],
    ));
    add(const SkillDefinition(
      canonical: 'DynamoDB',
      category: SkillCategory.database,
      kind: SkillKind.core,
    ));
    add(const SkillDefinition(
      canonical: 'Cassandra',
      category: SkillCategory.database,
      kind: SkillKind.core,
    ));
    add(const SkillDefinition(
      canonical: 'Elasticsearch',
      category: SkillCategory.database,
      kind: SkillKind.core,
      aliases: ['elastic search', 'elk'],
    ));
    add(const SkillDefinition(
      canonical: 'Snowflake',
      category: SkillCategory.data,
      kind: SkillKind.core,
    ));
    add(const SkillDefinition(
      canonical: 'BigQuery',
      category: SkillCategory.data,
      kind: SkillKind.core,
      implies: ['SQL'],
    ));

    // 4. Cloud & DevOps
    add(const SkillDefinition(
      canonical: 'Amazon Web Services',
      category: SkillCategory.cloud,
      kind: SkillKind.core,
      aliases: ['aws', 'amazon cloud'],
      related: {'GCP': 0.4, 'Azure': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'Google Cloud Platform',
      category: SkillCategory.cloud,
      kind: SkillKind.core,
      aliases: ['gcp', 'google cloud'],
      related: {'Amazon Web Services': 0.4, 'Azure': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'Microsoft Azure',
      category: SkillCategory.cloud,
      kind: SkillKind.core,
      aliases: ['azure'],
      related: {'Amazon Web Services': 0.4, 'Google Cloud Platform': 0.4},
    ));
    add(const SkillDefinition(
      canonical: 'Docker',
      category: SkillCategory.devops,
      kind: SkillKind.core,
      aliases: ['containerization', 'docker containers'],
      related: {'Kubernetes': 0.6},
    ));
    add(const SkillDefinition(
      canonical: 'Kubernetes',
      category: SkillCategory.devops,
      kind: SkillKind.core,
      aliases: ['k8s', 'kube'],
      related: {'Docker': 0.6},
    ));
    add(const SkillDefinition(
      canonical: 'Git',
      category: SkillCategory.tool,
      kind: SkillKind.supporting,
      aliases: ['version control'],
    ));
    add(const SkillDefinition(
      canonical: 'GitHub',
      category: SkillCategory.tool,
      kind: SkillKind.supporting,
      implies: ['Git'],
    ));
    add(const SkillDefinition(
      canonical: 'GitHub Actions',
      category: SkillCategory.devops,
      kind: SkillKind.supporting,
      implies: ['CI/CD'],
    ));
    add(const SkillDefinition(
      canonical: 'GitLab',
      category: SkillCategory.tool,
      kind: SkillKind.supporting,
      implies: ['Git'],
    ));
    add(const SkillDefinition(
      canonical: 'Jenkins',
      category: SkillCategory.devops,
      kind: SkillKind.core,
      implies: ['CI/CD'],
    ));
    add(const SkillDefinition(
      canonical: 'Terraform',
      category: SkillCategory.devops,
      kind: SkillKind.core,
      aliases: ['iac', 'infrastructure as code'],
    ));
    add(const SkillDefinition(
      canonical: 'Ansible',
      category: SkillCategory.devops,
      kind: SkillKind.core,
    ));
    add(const SkillDefinition(
      canonical: 'CI/CD',
      category: SkillCategory.devops,
      kind: SkillKind.supporting,
      aliases: ['continuous integration', 'continuous deployment'],
    ));
    add(const SkillDefinition(
      canonical: 'Linux',
      category: SkillCategory.devops,
      kind: SkillKind.supporting,
      aliases: ['unix', 'ubuntu', 'debian', 'centos'],
    ));
    add(const SkillDefinition(
      canonical: 'Nginx',
      category: SkillCategory.devops,
      kind: SkillKind.supporting,
    ));
    add(const SkillDefinition(
      canonical: 'Kafka',
      category: SkillCategory.backend,
      kind: SkillKind.core,
      aliases: ['apache kafka'],
    ));
    add(const SkillDefinition(
      canonical: 'RabbitMQ',
      category: SkillCategory.backend,
      kind: SkillKind.core,
    ));

    // 5. AI / ML / Data
    add(const SkillDefinition(
      canonical: 'Machine Learning',
      category: SkillCategory.ai_ml,
      kind: SkillKind.core,
      aliases: ['ml'],
    ));
    add(const SkillDefinition(
      canonical: 'Natural Language Processing',
      category: SkillCategory.ai_ml,
      kind: SkillKind.core,
      aliases: ['nlp'],
      implies: ['Machine Learning'],
    ));
    add(const SkillDefinition(
      canonical: 'Deep Learning',
      category: SkillCategory.ai_ml,
      kind: SkillKind.core,
      aliases: ['neural networks'],
      implies: ['Machine Learning'],
    ));
    add(const SkillDefinition(
      canonical: 'Large Language Models',
      category: SkillCategory.ai_ml,
      kind: SkillKind.core,
      aliases: ['llm', 'llms', 'generative ai', 'genai'],
      implies: ['Machine Learning', 'Natural Language Processing'],
    ));
    add(const SkillDefinition(
      canonical: 'TensorFlow',
      category: SkillCategory.ai_ml,
      kind: SkillKind.core,
      implies: ['Python', 'Machine Learning'],
    ));
    add(const SkillDefinition(
      canonical: 'PyTorch',
      category: SkillCategory.ai_ml,
      kind: SkillKind.core,
      implies: ['Python', 'Machine Learning'],
    ));
    add(const SkillDefinition(
      canonical: 'Pandas',
      category: SkillCategory.data,
      kind: SkillKind.supporting,
      implies: ['Python'],
    ));
    add(const SkillDefinition(
      canonical: 'NumPy',
      category: SkillCategory.data,
      kind: SkillKind.supporting,
      implies: ['Python'],
    ));
    add(const SkillDefinition(
      canonical: 'LangChain',
      category: SkillCategory.ai_ml,
      kind: SkillKind.core,
      implies: ['Large Language Models'],
    ));
    add(const SkillDefinition(
      canonical: 'Apache Spark',
      category: SkillCategory.data,
      kind: SkillKind.core,
      aliases: ['spark', 'pyspark'],
    ));
    add(const SkillDefinition(
      canonical: 'Hadoop',
      category: SkillCategory.data,
      kind: SkillKind.core,
      aliases: ['apache hadoop'],
    ));
    add(const SkillDefinition(
      canonical: 'Airflow',
      category: SkillCategory.data,
      kind: SkillKind.core,
      aliases: ['apache airflow'],
    ));

    // 6. Architecture, Protocols & Domain Skills
    add(const SkillDefinition(
      canonical: 'REST',
      category: SkillCategory.backend,
      kind: SkillKind.supporting,
      aliases: ['rest api', 'rest apis', 'restful', 'restful api'],
    ));
    add(const SkillDefinition(
      canonical: 'GraphQL',
      category: SkillCategory.backend,
      kind: SkillKind.core,
    ));
    add(const SkillDefinition(
      canonical: 'gRPC',
      category: SkillCategory.backend,
      kind: SkillKind.core,
    ));
    add(const SkillDefinition(
      canonical: 'Microservices',
      category: SkillCategory.backend,
      kind: SkillKind.supporting,
      aliases: ['microservice architecture', 'microservice'],
    ));
    add(const SkillDefinition(
      canonical: 'WebSockets',
      category: SkillCategory.backend,
      kind: SkillKind.supporting,
      aliases: ['websocket', 'socket.io'],
    ));
    add(const SkillDefinition(
      canonical: 'OAuth',
      category: SkillCategory.backend,
      kind: SkillKind.supporting,
      aliases: ['oauth2', 'jwt', 'authentication', 'auth0'],
    ));
    add(const SkillDefinition(
      canonical: 'System Design',
      category: SkillCategory.backend,
      kind: SkillKind.supporting,
      aliases: ['distributed systems'],
    ));
    add(const SkillDefinition(
      canonical: 'Clean Architecture',
      category: SkillCategory.mobile,
      kind: SkillKind.supporting,
      aliases: ['solid principles', 'design patterns', 'mvvm'],
    ));
    add(const SkillDefinition(
      canonical: 'Data Structures and Algorithms',
      category: SkillCategory.backend,
      kind: SkillKind.supporting,
      aliases: ['dsa', 'algorithms', 'data structures'],
    ));
    add(const SkillDefinition(
      canonical: 'Unit Testing',
      category: SkillCategory.testing,
      kind: SkillKind.supporting,
      aliases: ['tdd', 'test driven development', 'jest', 'mocha', 'junit', 'pytest'],
    ));

    // Expand taxonomy with standard industry skills up to 400+
    _expandTaxonomy(add);
  }

  static void _expandTaxonomy(void Function(SkillDefinition) add) {
    final extraSkills = [
      ('Tailwind CSS', SkillCategory.frontend, ['tailwind']),
      ('Bootstrap', SkillCategory.frontend, <String>[]),
      ('Sass', SkillCategory.frontend, ['scss']),
      ('Webpack', SkillCategory.tool, <String>[]),
      ('Vite', SkillCategory.tool, <String>[]),
      ('Redux', SkillCategory.frontend, ['redux toolkit']),
      ('Zustand', SkillCategory.frontend, <String>[]),
      ('MobX', SkillCategory.frontend, <String>[]),
      ('RxDart', SkillCategory.mobile, <String>[]),
      ('RxJava', SkillCategory.backend, <String>[]),
      ('Prisma', SkillCategory.database, <String>[]),
      ('TypeORM', SkillCategory.database, <String>[]),
      ('Hibernate', SkillCategory.database, <String>[]),
      ('Dapper', SkillCategory.database, <String>[]),
      ('Entity Framework', SkillCategory.database, ['ef core']),
      ('GraphQL Yoga', SkillCategory.backend, <String>[]),
      ('Apollo GraphQL', SkillCategory.backend, ['apollo']),
      ('Prometheus', SkillCategory.devops, <String>[]),
      ('Grafana', SkillCategory.devops, <String>[]),
      ('Datadog', SkillCategory.devops, <String>[]),
      ('Postman', SkillCategory.tool, <String>[]),
      ('Figma', SkillCategory.tool, <String>[]),
      ('Jira', SkillCategory.tool, <String>[]),
      ('Confluence', SkillCategory.tool, <String>[]),
      ('Vercel', SkillCategory.cloud, <String>[]),
      ('Netlify', SkillCategory.cloud, <String>[]),
      ('Heroku', SkillCategory.cloud, <String>[]),
      ('Render', SkillCategory.cloud, <String>[]),
      ('Cloudflare', SkillCategory.cloud, ['cloudflare workers']),
      ('Fastly', SkillCategory.cloud, <String>[]),
      ('Akamai', SkillCategory.cloud, <String>[]),
      ('CircleCI', SkillCategory.devops, <String>[]),
      ('Travis CI', SkillCategory.devops, <String>[]),
      ('Bitbucket', SkillCategory.tool, <String>[]),
      ('OpenAPI', SkillCategory.tool, ['swagger']),
      ('Selenium', SkillCategory.testing, <String>[]),
      ('Cypress', SkillCategory.testing, <String>[]),
      ('Playwright', SkillCategory.testing, <String>[]),
      ('Puppeteer', SkillCategory.testing, <String>[]),
      ('Appium', SkillCategory.testing, <String>[]),
      ('Espresso', SkillCategory.testing, <String>[]),
      ('XCTest', SkillCategory.testing, <String>[]),
      ('Detox', SkillCategory.testing, <String>[]),
      ('Cucumber', SkillCategory.testing, ['bdd']),
      ('SonarQube', SkillCategory.tool, <String>[]),
      ('OpenShift', SkillCategory.devops, <String>[]),
      ('Helm', SkillCategory.devops, <String>[]),
      ('ArgoCD', SkillCategory.devops, <String>[]),
      ('Flux', SkillCategory.devops, <String>[]),
      ('Istio', SkillCategory.devops, <String>[]),
      ('Linkerd', SkillCategory.devops, <String>[]),
      ('Consul', SkillCategory.devops, <String>[]),
      ('Vault', SkillCategory.devops, ['hashicorp vault']),
      ('Nomad', SkillCategory.devops, <String>[]),
      ('Splunk', SkillCategory.devops, <String>[]),
      ('New Relic', SkillCategory.devops, <String>[]),
      ('Sentry', SkillCategory.devops, <String>[]),
      ('Logstash', SkillCategory.devops, <String>[]),
      ('Kibana', SkillCategory.devops, <String>[]),
      ('Fluentd', SkillCategory.devops, <String>[]),
      ('OpenTelemetry', SkillCategory.devops, ['otel']),
      ('Jaeger', SkillCategory.devops, <String>[]),
      ('Zipkin', SkillCategory.devops, <String>[]),
      ('Scikit-Learn', SkillCategory.ai_ml, ['sklearn']),
      ('XGBoost', SkillCategory.ai_ml, <String>[]),
      ('LightGBM', SkillCategory.ai_ml, <String>[]),
      ('CatBoost', SkillCategory.ai_ml, <String>[]),
      ('OpenCV', SkillCategory.ai_ml, <String>[]),
      ('Keras', SkillCategory.ai_ml, <String>[]),
      ('Hugging Face', SkillCategory.ai_ml, ['transformers']),
      ('LlamaIndex', SkillCategory.ai_ml, <String>[]),
      ('ChromaDB', SkillCategory.ai_ml, ['chroma']),
      ('Pinecone', SkillCategory.ai_ml, <String>[]),
      ('Weaviate', SkillCategory.ai_ml, <String>[]),
      ('Milvus', SkillCategory.ai_ml, <String>[]),
      ('Qdrant', SkillCategory.ai_ml, <String>[]),
      ('FAISS', SkillCategory.ai_ml, <String>[]),
      ('Ollama', SkillCategory.ai_ml, <String>[]),
      ('vLLM', SkillCategory.ai_ml, <String>[]),
      ('Ray', SkillCategory.ai_ml, ['ray tune']),
      ('Dask', SkillCategory.data, <String>[]),
      ('Polars', SkillCategory.data, <String>[]),
      ('DuckDB', SkillCategory.database, <String>[]),
      ('ClickHouse', SkillCategory.database, <String>[]),
      ('Neo4j', SkillCategory.database, <String>[]),
      ('Couchbase', SkillCategory.database, <String>[]),
      ('CockroachDB', SkillCategory.database, <String>[]),
      ('TiDB', SkillCategory.database, <String>[]),
      ('ScyllaDB', SkillCategory.database, <String>[]),
      ('MariaDB', SkillCategory.database, <String>[]),
      ('Oracle DB', SkillCategory.database, ['oracle database', 'pl/sql']),
      ('Microsoft SQL Server', SkillCategory.database, ['mssql', 't-sql', 'sql server']),
      ('dbt', SkillCategory.data, ['data build tool']),
      ('Fivetran', SkillCategory.data, <String>[]),
      ('Airbyte', SkillCategory.data, <String>[]),
      ('Kafka Connect', SkillCategory.data, <String>[]),
      ('Debezium', SkillCategory.data, <String>[]),
      ('Kinesis', SkillCategory.cloud, ['aws kinesis']),
      ('EventBridge', SkillCategory.cloud, ['aws eventbridge']),
      ('Lambda', SkillCategory.cloud, ['aws lambda', 'serverless']),
      ('Cloud Functions', SkillCategory.cloud, ['gcp cloud functions']),
      ('Azure Functions', SkillCategory.cloud, <String>[]),
      ('ECS', SkillCategory.cloud, ['aws ecs']),
      ('EKS', SkillCategory.cloud, ['aws eks']),
      ('GKE', SkillCategory.cloud, ['google kubernetes engine']),
      ('AKS', SkillCategory.cloud, ['azure kubernetes service']),
      ('S3', SkillCategory.cloud, ['aws s3', 'amazon s3']),
      ('CloudFront', SkillCategory.cloud, ['aws cloudfront']),
      ('API Gateway', SkillCategory.cloud, ['aws api gateway']),
      ('SQS', SkillCategory.cloud, ['aws sqs']),
      ('SNS', SkillCategory.cloud, ['aws sns']),
      ('Shopify', SkillCategory.tool, ['shopify liquid', 'liquid']),
      ('WordPress', SkillCategory.tool, ['wp']),
      ('Webflow', SkillCategory.tool, <String>[]),
      ('Wix', SkillCategory.tool, <String>[]),
      ('Web3', SkillCategory.tool, ['web3.js', 'ethers.js']),
      ('Hardhat', SkillCategory.tool, <String>[]),
      ('Truffle', SkillCategory.tool, <String>[]),
    ];

    for (final e in extraSkills) {
      add(SkillDefinition(
        canonical: e.$1,
        category: e.$2,
        kind: SkillKind.supporting,
        aliases: e.$3,
      ));
    }
  }

  static Map<String, SkillDefinition> get allSkills {
    _init();
    return _skills;
  }

  static SkillDefinition? lookup(String term) {
    _init();
    final lower = term.trim().toLowerCase();
    final canonicalName = _aliasToCanonical[lower];
    if (canonicalName != null) {
      return _skills[canonicalName.toLowerCase()];
    }
    return _skills[lower];
  }

  static String? normalizeToCanonical(String term) {
    _init();
    return _aliasToCanonical[term.trim().toLowerCase()];
  }
}
