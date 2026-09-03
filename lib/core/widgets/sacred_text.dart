import 'package:flutter/material.dart';

/// Text that colors the divine names, the saints and the holy honorifics.
///
/// Matching is anchored on Ethiopic word boundaries. Dart's `\b` only knows
/// `[A-Za-z0-9_]`, so it cannot anchor Ge'ez; without the lookarounds below a
/// short term such as `አብ` matches inside unrelated words and colors half of
/// `አብርሃም`.
class SacredText extends StatelessWidget {
  const SacredText(
    this.text, {
    required this.sacredColor,
    this.sacredFontWeight,
    this.enabled = true,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final Color sacredColor;
  final FontWeight? sacredFontWeight;
  final bool enabled;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Ethiopic syllables and their combining marks, without the punctuation and
  /// numerals that start at U+1360. A full stop must end a word, not extend it.
  static const String _ethiopicLetter =
      '\u1200-\u135A\u135D-\u135F\u2D80-\u2DDF';

  static const List<String> _divineNames = [
    'እግዚአብሔር አብ',
    'መድኃኒተ ዓለም',
    'መድኃኔ ዓለም',
    'ወላዲተ አምላክ',
    'ድንግል ማርያም',
    'መንፈስ ቅዱስ',
    'ቅዱስ ሥሉስ',
    'እግዚአብሔር',
    'እመቤታችን',
    'ጰራቅሊጦስ',
    'አማኑኤል',
    'ኢየሱስ',
    'ክርስቶስ',
    'እግዚኦ',
    'እግዚእ',
    'ማርያም',
    'ድንግል',
    'ሥላሴ',
    'አምላክ',
    'ወልደ',
    'ወልድ',
    'አብ',
  ];

  /// Saints named in red on their own, so `ቅዱስ` needs no rule that swallows
  /// whatever word follows it. Multi-word names are listed whole.
  static const List<String> _saintNames = [
    // Anaphora saints.
    'ዲዮስቆሮስ',
    'አትናቴዎስ',
    'ኤጲፋንዮስ',
    'ጎርጎርዮስ',
    'ባስልዮስ',
    'አፈወርቅ',
    'ቄርሎስ',
    'ኩርሎስ',
    'ያዕቆብ',
    'ዮሐንስ',
    // Apostles and evangelists.
    'በርተሎሜዎስ',
    'እስጢፋኖስ',
    'እንድርያስ',
    'ናትናኤል',
    'ጴጥሮስ',
    'ፊልጶስ',
    'ማቴዎስ',
    'ማርቆስ',
    'ታዴዎስ',
    'ማትያስ',
    'ስምዖን',
    'ጳውሎስ',
    'ሉቃስ',
    'ቶማስ',
    // Archangels.
    'ገብርኤል',
    'ሚካኤል',
    'ሩፋኤል',
    'ኡራኤል',
    'ፋኑኤል',
    // Ethiopian and other commemorated saints.
    'ገብረ መንፈስ ቅዱስ',
    'ተክለ ሃይማኖት',
    'መርቆሬዎስ',
    'ጊዮርጊስ',
    'አረጋዊ',
    'አርሴማ',
    'ዮሴፍ',
    'ያሬድ',
    'ዳዊት',
  ];

  static const List<String> _honorifics = ['ቅዱሳን', 'ቅድስት', 'ቅዱስ'];

  /// Prefixes Ethiopic grammar attaches to a name: the conjunctions and
  /// prepositions, plus `እም` (from) and the relative `ዘ`.
  static const String _prefixes = r'(?:እም|ዘ|[ለበወየከ])*';

  /// Suffixes that legitimately attach to a name, chiefly the possessives:
  /// `አምላክነ` (our God), `ወልድከ` (thy Son), `እግዚእየ` (my Lord). Up to two, since
  /// they stack. Anything else following a term means the term is only a
  /// fragment of a longer word, and then nothing is colored at all.
  static const String _suffixes =
      r'(?:ንም|ችን|ሆሙ|ክሙ|ን|ም|ስ|ና|ው|ሂ|ሰ|ኒ|ኬ|ነ|ከ|ኪ|የ|ሁ|ሙ|ሃ|ክ){0,2}';

  /// Ordinary words a term plus a legitimate particle happens to spell.
  /// `ድንግል` + `ና` spells `ድንግልና`, virginity, which is a noun and not a name.
  static final RegExp _notAName = RegExp('^$_prefixes(?:ድንግልና)', unicode: true);

  static final String _ethiopicTermPattern = ([
    ..._divineNames,
    ..._saintNames,
    ..._honorifics,
  ]..sort((a, b) => b.length.compareTo(a.length))).map(RegExp.escape).join('|');

  static final RegExp _sacredPattern = RegExp(
    [
      // Ethiopic grammar attaches conjunctions, prepositions and case markers.
      // The lookarounds keep the term from matching inside a longer word.
      '(?<![$_ethiopicLetter])'
          '$_prefixes'
          '(?:$_ethiopicTermPattern)'
          '$_suffixes'
          '(?![$_ethiopicLetter])',
      r'\b(?:God the Father|Holy Trinity|Savior of the World|'
          r'Mother of God|Holy Spirit|Virgin Mary|Our Lady|Paraclete|'
          r'Emmanuel|Theotokos|God|Lord|Jesus|Christ|Mary|Trinity|Son)\b',
      r'\b(?:Saint|St\.)\s+[A-Z][A-Za-zʼʽ-]+',
    ].join('|'),
    unicode: true,
  );

  @override
  Widget build(BuildContext context) {
    if (!enabled || text.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _sacredPattern.allMatches(text)) {
      if (_notAName.hasMatch(match.group(0)!)) {
        continue;
      }
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: sacredColor,
            fontWeight: sacredFontWeight ?? FontWeight.w600,
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// The sacred runs [text] would color, in order. Exposed for tests.
  @visibleForTesting
  static List<String> matchesIn(String text) {
    return _sacredPattern
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where((m) => !_notAName.hasMatch(m))
        .toList();
  }
}
