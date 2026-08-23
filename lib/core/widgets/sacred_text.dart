import 'package:flutter/material.dart';

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

  static const List<String> _ethiopicTerms = [
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
    'ወልድ',
    'አብ',
  ];

  static final String _ethiopicTermPattern = _ethiopicTerms
      .map(RegExp.escape)
      .join('|');

  static final RegExp _sacredPattern = RegExp(
    [
      // Ethiopic grammar attaches conjunctions, prepositions, and case markers.
      // Keep these controlled so nearby non-sacred words are not colored.
      r'[ለበወየከ]*(?:' + _ethiopicTermPattern + r')(?:ንም|ን|ም|ስ)?',
      r'[ለበወየከ]*(?:ቅዱስ|ቅድስት|ቅዱሳን)\s+'
          r'[^\s።፤፥፣,.;:]+',
      r'\b(?:God the Father|Holy Trinity|Savior of the World|'
          r'Mother of God|Holy Spirit|Virgin Mary|Our Lady|Paraclete|'
          r'Emmanuel|Theotokos|God|Lord|Jesus|Christ|Mary|Trinity|Son)\b',
      r'\b(?:Saint|St\.)\s+[A-Z][A-Za-zʼʽ-]+',
    ].join('|'),
    caseSensitive: false,
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
}
