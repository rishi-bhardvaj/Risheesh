import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/core/fx/fx_service.dart';
import 'package:career_os/features/career/domain/salary_parser.dart';

void main() {
  late AppDatabase db;
  late FxService fx;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fx = FxService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SalaryParser Tests (Indian & Global Currencies)', () {
    test('Parses Indian LPA and Lakhs formats', () {
      final r1 = SalaryParser.parse('₹12 LPA');
      expect(r1, isNotNull);
      expect(r1!.currency, equals('INR'));
      expect(r1.min, equals(1200000));
      expect(r1.max, equals(1200000));

      final r2 = SalaryParser.parse('12–18 lakhs per annum');
      expect(r2, isNotNull);
      expect(r2!.currency, equals('INR'));
      expect(r2.min, equals(1200000));
      expect(r2.max, equals(1800000));
    });

    test('Parses Crores format', () {
      final r = SalaryParser.parse('1.2 Cr CTC');
      expect(r, isNotNull);
      expect(r!.currency, equals('INR'));
      expect(r.max, equals(12000000));
    });

    test('Parses USD range and hourly / monthly rates', () {
      final range = SalaryParser.parse(r'$120k – $150k');
      expect(range, isNotNull);
      expect(range!.currency, equals('USD'));
      expect(range.min, equals(120000));
      expect(range.max, equals(150000));

      final hourly = SalaryParser.parse(r'$60/hr');
      expect(hourly, isNotNull);
      expect(hourly!.min, equals(60 * 2080));

      final monthly = SalaryParser.parse('€5,000/month');
      expect(monthly, isNotNull);
      expect(monthly!.currency, equals('EUR'));
      expect(monthly.min, equals(60000));
    });
  });

  group('FxService Currency Conversion Tests', () {
    test('Converts between currencies using bundled baseline rates', () {
      final inrToUsd = fx.convert(100000, 'INR', 'USD');
      expect(inrToUsd, closeTo(1200, 10)); // 100k INR * 0.012 = $1200

      final usdToInr = fx.convert(1000, 'USD', 'INR');
      expect(usdToInr, closeTo(83333, 100)); // $1000 / 0.012 = 83,333 INR

      final same = fx.convert(500, 'EUR', 'EUR');
      expect(same, equals(500));
    });

    test('Formats salary with human readable tags', () {
      expect(FxService.formatSalary(1800000, 'INR'), equals('₹18 LPA'));
      expect(FxService.formatSalary(12000000, 'INR'), equals('₹1.2 Cr /yr'));
      expect(FxService.formatSalary(150000, 'USD'), equals(r'$150k /yr'));
      expect(FxService.formatSalary(60000, 'EUR'), equals('€60k /yr'));
    });

    test('Meets salary filter threshold (at least 90% expected)', () {
      const candidateExpectedYearlyInr = 1800000.0; // 18 LPA
      const threshold = candidateExpectedYearlyInr * 0.90; // 16.2 LPA

      bool meetsSalary(double? jobMaxInr) {
        if (jobMaxInr == null) return false;
        return jobMaxInr >= threshold;
      }

      expect(meetsSalary(2000000), isTrue); // 20 LPA
      expect(meetsSalary(1650000), isTrue); // 16.5 LPA (meets 90%)
      expect(meetsSalary(1500000), isFalse); // 15 LPA (under 90%)
      expect(meetsSalary(null), isFalse);
    });
  });
}
