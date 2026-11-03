/// A deliberately limited, deterministic collation profile for the simulator.
///
/// It is not a replacement for Windows/SQL Server linguistic collation tables.
/// It provides a testable classroom subset: case sensitivity, selected Latin
/// accents, and Arabic combining marks. Ordering is ordinal after normalization.
class SqlCollationProfile {
  final String name;
  final bool caseSensitive;
  final bool accentSensitive;

  const SqlCollationProfile({
    required this.name,
    this.caseSensitive = false,
    this.accentSensitive = true,
  });

  static const educationalCiAs = SqlCollationProfile(
    name: 'SSS_Unicode_CI_AS',
    caseSensitive: false,
    accentSensitive: true,
  );

  static const educationalCiAi = SqlCollationProfile(
    name: 'SSS_Unicode_CI_AI',
    caseSensitive: false,
    accentSensitive: false,
  );

  static const educationalCsAs = SqlCollationProfile(
    name: 'SSS_Unicode_CS_AS',
    caseSensitive: true,
    accentSensitive: true,
  );
}

class SqlCollationService {
  const SqlCollationService();

  /// Returns -1, 0, or 1 using the simulator's documented normalization rules.
  int compare(
    String left,
    String right, {
    SqlCollationProfile profile =
        SqlCollationProfile.educationalCiAs,
  }) {
    final a = sortKey(left, profile: profile);
    final b = sortKey(right, profile: profile);
    final result = a.compareTo(b);
    return result < 0 ? -1 : (result > 0 ? 1 : 0);
  }

  bool equals(
    String left,
    String right, {
    SqlCollationProfile profile =
        SqlCollationProfile.educationalCiAs,
  }) =>
      compare(left, right, profile: profile) == 0;

  String sortKey(
    String value, {
    SqlCollationProfile profile =
        SqlCollationProfile.educationalCiAs,
  }) {
    var result = value;
    if (!profile.caseSensitive) {
      result = result.toLowerCase();
    }
    if (!profile.accentSensitive) {
      result = _removeSupportedDiacritics(result);
    }
    return result;
  }

  String _removeSupportedDiacritics(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      // Arabic harakat and superscript alef. This is a teaching rule,
      // not a claim of exact SQL Server Arabic collation behavior.
      if ((rune >= 0x064B && rune <= 0x065F) || rune == 0x0670) {
        continue;
      }
      final character = String.fromCharCode(rune);
      buffer.write(_latinAccentBase[character] ?? character);
    }
    return buffer.toString();
  }

  static const Map<String, String> _latinAccentBase = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'ā': 'a', 'ă': 'a', 'ą': 'a',
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
    'Ā': 'A', 'Ă': 'A', 'Ą': 'A',
    'ç': 'c', 'ć': 'c', 'č': 'c', 'ĉ': 'c', 'ċ': 'c',
    'Ç': 'C', 'Ć': 'C', 'Č': 'C', 'Ĉ': 'C', 'Ċ': 'C',
    'ď': 'd', 'đ': 'd', 'Ď': 'D', 'Đ': 'D',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e',
    'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ē': 'E', 'Ė': 'E', 'Ę': 'E',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i',
    'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I', 'Ī': 'I', 'Į': 'I',
    'ñ': 'n', 'ń': 'n', 'ň': 'n', 'Ñ': 'N', 'Ń': 'N', 'Ň': 'N',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
    'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O', 'Ø': 'O', 'Ō': 'O',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'Ù': 'U', 'Ú': 'U',
    'Û': 'U', 'Ü': 'U', 'Ū': 'U',
    'ý': 'y', 'ÿ': 'y', 'Ý': 'Y', 'Ÿ': 'Y',
    'š': 's', 'ś': 's', 'ş': 's', 'Š': 'S', 'Ś': 'S', 'Ş': 'S',
    'ž': 'z', 'ź': 'z', 'ż': 'z', 'Ž': 'Z', 'Ź': 'Z', 'Ż': 'Z',
  };
}
