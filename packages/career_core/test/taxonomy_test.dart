import 'package:test/test.dart';
import 'package:career_core/career_core.dart';

void main() {
  group('Taxonomy & Normalization Tests (M3)', () {
    test('Equivalences match to correct canonicals', () {
      expect(SkillTaxonomy.normalizeToCanonical('JS'), 'JavaScript');
      expect(SkillTaxonomy.normalizeToCanonical('ecmascript'), 'JavaScript');
      expect(SkillTaxonomy.normalizeToCanonical('es6'), 'JavaScript');
      expect(SkillTaxonomy.normalizeToCanonical('TS'), 'TypeScript');
      expect(SkillTaxonomy.normalizeToCanonical('Postgres'), 'PostgreSQL');
      expect(SkillTaxonomy.normalizeToCanonical('ML'), 'Machine Learning');
      expect(SkillTaxonomy.normalizeToCanonical('NLP'), 'Natural Language Processing');
      expect(SkillTaxonomy.normalizeToCanonical('AWS'), 'Amazon Web Services');
      expect(SkillTaxonomy.normalizeToCanonical('K8s'), 'Kubernetes');
      expect(SkillTaxonomy.normalizeToCanonical('golang'), 'Go');
      expect(SkillTaxonomy.normalizeToCanonical('csharp'), 'C#');
      expect(SkillTaxonomy.normalizeToCanonical('dotnet'), '.NET');
      expect(SkillTaxonomy.normalizeToCanonical('node'), 'Node.js');
      expect(SkillTaxonomy.normalizeToCanonical('nodejs'), 'Node.js');
      expect(SkillTaxonomy.normalizeToCanonical('reactjs'), 'React');
      expect(SkillTaxonomy.normalizeToCanonical('react.js'), 'React');
    });

    test('Non-equivalences must be strictly separated', () {
      // Java != JavaScript
      expect(SkillTaxonomy.normalizeToCanonical('Java'), 'Java');
      expect(SkillTaxonomy.normalizeToCanonical('JavaScript'), 'JavaScript');
      expect(SkillTaxonomy.normalizeToCanonical('Java'), isNot(equals(SkillTaxonomy.normalizeToCanonical('JavaScript'))));

      // React != React Native
      expect(SkillTaxonomy.normalizeToCanonical('React'), 'React');
      expect(SkillTaxonomy.normalizeToCanonical('React Native'), 'React Native');
      expect(SkillTaxonomy.normalizeToCanonical('React'), isNot(equals(SkillTaxonomy.normalizeToCanonical('React Native'))));

      // Spring != Spring Boot (related, but distinct)
      expect(SkillTaxonomy.normalizeToCanonical('Spring'), 'Spring');
      expect(SkillTaxonomy.normalizeToCanonical('Spring Boot'), 'Spring Boot');
      expect(SkillTaxonomy.normalizeToCanonical('Spring'), isNot(equals(SkillTaxonomy.normalizeToCanonical('Spring Boot'))));

      // Cloud providers are distinct
      final aws = SkillTaxonomy.normalizeToCanonical('AWS');
      final azure = SkillTaxonomy.normalizeToCanonical('Azure');
      final gcp = SkillTaxonomy.normalizeToCanonical('GCP');
      expect(aws, isNot(equals(azure)));
      expect(azure, isNot(equals(gcp)));

      // SQL != PostgreSQL
      expect(SkillTaxonomy.normalizeToCanonical('SQL'), 'SQL');
      expect(SkillTaxonomy.normalizeToCanonical('PostgreSQL'), 'PostgreSQL');
      expect(SkillTaxonomy.normalizeToCanonical('SQL'), isNot(equals(SkillTaxonomy.normalizeToCanonical('PostgreSQL'))));

      // C != C++ != C#
      expect(SkillTaxonomy.normalizeToCanonical('C'), 'C');
      expect(SkillTaxonomy.normalizeToCanonical('C++'), 'C++');
      expect(SkillTaxonomy.normalizeToCanonical('C#'), 'C#');
      expect(SkillTaxonomy.normalizeToCanonical('C'), isNot(equals('C++')));
      expect(SkillTaxonomy.normalizeToCanonical('C++'), isNot(equals('C#')));
    });

    test('Implications work only in implied direction', () {
      // PostgreSQL implies SQL
      final pgMatch = SkillMatcher.matchSkill(
        jobSkill: 'SQL',
        candidateCanonicalSkills: {'PostgreSQL'},
      );
      expect(pgMatch.quality, SkillMatchQuality.equivalent);

      // But SQL does NOT imply PostgreSQL
      final sqlMatch = SkillMatcher.matchSkill(
        jobSkill: 'PostgreSQL',
        candidateCanonicalSkills: {'SQL'},
      );
      expect(sqlMatch.quality, SkillMatchQuality.none);

      // Spring Boot implies Spring
      final springMatch = SkillMatcher.matchSkill(
        jobSkill: 'Spring',
        candidateCanonicalSkills: {'Spring Boot'},
      );
      expect(springMatch.quality, SkillMatchQuality.equivalent);

      // Next.js implies React
      final reactMatch = SkillMatcher.matchSkill(
        jobSkill: 'React',
        candidateCanonicalSkills: {'Next.js'},
      );
      expect(reactMatch.quality, SkillMatchQuality.equivalent);

      // TypeScript implies JavaScript
      final jsMatch = SkillMatcher.matchSkill(
        jobSkill: 'JavaScript',
        candidateCanonicalSkills: {'TypeScript'},
      );
      expect(jsMatch.quality, SkillMatchQuality.equivalent);
    });

    test('Generic stoplist is never extracted as a skill', () {
      const text = 'Looking for a senior software engineer with strong leadership and communication skills in agile development and IT platform tools.';
      final extracted = SkillMatcher.extractCanonicalSkills(text);
      expect(extracted.contains('Software'), isFalse);
      expect(extracted.contains('Developer'), isFalse);
      expect(extracted.contains('Engineer'), isFalse);
      expect(extracted.contains('IT'), isFalse);
      expect(extracted.contains('Tools'), isFalse);
      expect(extracted.contains('Agile'), isFalse);
      expect(extracted.contains('Communication'), isFalse);
    });

    test('Edge tokens with symbols are correctly extracted', () {
      const text = 'Must know C++, C#, .NET core, Node.js, and CI/CD pipelines.';
      final extracted = SkillMatcher.extractCanonicalSkills(text);
      expect(extracted.contains('C++'), isTrue);
      expect(extracted.contains('C#'), isTrue);
      expect(extracted.contains('.NET'), isTrue);
      expect(extracted.contains('Node.js'), isTrue);
      expect(extracted.contains('CI/CD'), isTrue);
    });

    test('Go and R boundary isolation', () {
      // "go-to" and "go live" must NOT match Go
      const sentence1 = 'This is our go-to solution for the project before we go live.';
      expect(SkillMatcher.extractCanonicalSkills(sentence1).contains('Go'), isFalse);

      // "Golang" or "Go developer" matches Go
      const sentence2 = 'Senior Golang backend engineer building services.';
      expect(SkillMatcher.extractCanonicalSkills(sentence2).contains('Go'), isTrue);

      // Stray letter 'r' does not match R
      const sentence3 = 'We need a senior person for our R & D department.';
      expect(SkillMatcher.extractCanonicalSkills(sentence3).contains('R'), isFalse);

      // "R programming" matches R
      const sentence4 = 'Data scientist proficient in R programming and statistical analysis.';
      expect(SkillMatcher.extractCanonicalSkills(sentence4).contains('R'), isTrue);
    });

    test('Micro-benchmark: matching 10k characters completes in under 50ms', () {
      final buffer = StringBuffer();
      for (var i = 0; i < 50; i++) {
        buffer.writeln(
          'We are seeking a Full Stack Flutter Developer proficient with Dart, Riverpod, SQLite, Drift, '
          'Firebase, Docker, Kubernetes, AWS, PostgreSQL, and REST APIs. Experience with Node.js and TypeScript '
          'is preferred. Solid understanding of CI/CD, Git, and automated testing is required.',
        );
      }
      final corpus = buffer.toString();
      expect(corpus.length, greaterThan(10000));

      final stopwatch = Stopwatch()..start();
      final skills = SkillMatcher.extractCanonicalSkills(corpus);
      stopwatch.stop();

      expect(skills.contains('Flutter'), isTrue);
      expect(skills.contains('Dart'), isTrue);
      expect(skills.contains('PostgreSQL'), isTrue);
      expect(skills.contains('Docker'), isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
