import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/types/sql_collation.dart';

void main() {
  const service = SqlCollationService();

  group('Simulator collation profile', () {
    test('case-insensitive profile equates Latin case variants', () {
      expect(
        service.equals('Student', 'STUDENT'),
        isTrue,
      );
    });

    test('case-sensitive profile distinguishes case variants', () {
      expect(
        service.equals(
          'Student',
          'STUDENT',
          profile: SqlCollationProfile.educationalCsAs,
        ),
        isFalse,
      );
    });

    test('accent-insensitive profile folds selected Latin accents', () {
      expect(
        service.equals(
          'café',
          'CAFE',
          profile: SqlCollationProfile.educationalCiAi,
        ),
        isTrue,
      );
    });

    test('accent-sensitive profile preserves Latin accents', () {
      expect(
        service.equals(
          'café',
          'cafe',
          profile: SqlCollationProfile.educationalCiAs,
        ),
        isFalse,
      );
    });

    test('Arabic Unicode is preserved and optional harakat folding is explicit',
        () {
      expect(
        service.equals(
          'عَرَبِيّ',
          'عربي',
          profile: SqlCollationProfile.educationalCiAi,
        ),
        isTrue,
      );
      expect(
        service.equals(
          'عَرَبِيّ',
          'عربي',
          profile: SqlCollationProfile.educationalCiAs,
        ),
        isFalse,
      );
    });

    test('compare returns normalized ordinal ordering', () {
      expect(service.compare('alpha', 'BETA'), lessThan(0));
    });
  });
}
