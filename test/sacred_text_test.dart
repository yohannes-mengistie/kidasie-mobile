import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_liturgy/core/widgets/sacred_text.dart';

void main() {
  group('does not color a fragment of another word', () {
    test('a name that only starts a longer word', () {
      expect(SacredText.matchesIn('አብርሃም ወይስሐቅ ወያዕቆብ'), ['ወያዕቆብ']);
      expect(SacredText.matchesIn('አብያተ ክርስቲያናት'), isEmpty);
      expect(SacredText.matchesIn('አብነት'), isEmpty);
    });

    test('an ordinary word a name and a particle happen to spell', () {
      expect(SacredText.matchesIn('ድንግልና ወንጽሕና'), isEmpty);
      expect(SacredText.matchesIn('በድንግልና ወለደቶ'), isEmpty);
    });

    test('a name buried in the middle of a word', () {
      expect(SacredText.matchesIn('ተአብዮ ወተሰብሐ'), isEmpty);
    });
  });

  group('colors whole words', () {
    test('a bare divine name', () {
      expect(SacredText.matchesIn('ወልደ አብ ዘእምቅድመ ዓለም'), ['ወልደ', 'አብ']);
    });

    test('a name carrying a prefix or a particle', () {
      expect(SacredText.matchesIn('ማርያምና ዮሴፍ'), ['ማርያምና', 'ዮሴፍ']);
      expect(SacredText.matchesIn('እግዚአብሔርን አመስግኑ'), ['እግዚአብሔርን']);
      expect(SacredText.matchesIn('ወወልድ ወመንፈስ ቅዱስ'), ['ወወልድ', 'ወመንፈስ ቅዱስ']);
    });

    test('a name carrying a possessive, as the liturgy text mostly does', () {
      expect(SacredText.matchesIn('እግዚእነ ወአምላክነ ወመድኃኒነ'), ['እግዚእነ', 'ወአምላክነ']);
      expect(SacredText.matchesIn('ወልድከ ወወልድኪ'), ['ወልድከ', 'ወወልድኪ']);
      expect(SacredText.matchesIn('እግዚእየ ወአምላኪየ'), ['እግዚእየ']);
      expect(SacredText.matchesIn('እምአብ ቅድመ ዓለም'), ['እምአብ']);
    });

    test('a possessive stem is still not a licence for any word', () {
      expect(SacredText.matchesIn('አምላክነት'), isEmpty);
      expect(SacredText.matchesIn('እምነት ተስፋ ፍቅር'), isEmpty);
    });

    test('a name closed by Ethiopic punctuation', () {
      expect(SacredText.matchesIn('ስብሐት ለእግዚአብሔር።'), ['ለእግዚአብሔር']);
    });

    test('the longest name wins over the ones inside it', () {
      expect(SacredText.matchesIn('እግዚአብሔር አብ'), ['እግዚአብሔር አብ']);
      expect(SacredText.matchesIn('ድንግል ማርያም'), ['ድንግል ማርያም']);
    });
  });

  group('honorifics and saints', () {
    test('an honorific never swallows the word after it', () {
      expect(SacredText.matchesIn('ቅዱስ ነው ስሙ'), ['ቅዱስ']);
    });

    test('a repeated honorific colors each one on its own', () {
      expect(SacredText.matchesIn('ቅዱስ ቅዱስ ቅዱስ እግዚአብሔር ጸባኦት'), [
        'ቅዱስ',
        'ቅዱስ',
        'ቅዱስ',
        'እግዚአብሔር',
      ]);
    });

    test('a known saint is colored beside the honorific', () {
      expect(SacredText.matchesIn('ቅዱስ ጊዮርጊስ'), ['ቅዱስ', 'ጊዮርጊስ']);
      expect(SacredText.matchesIn('አቡነ ተክለ ሃይማኖት'), ['ተክለ ሃይማኖት']);
      expect(SacredText.matchesIn('ቅዱስ ያዕቆብ ዘሥሩግ'), ['ቅዱስ', 'ያዕቆብ']);
    });
  });

  group('English', () {
    test('an ordinary lowercase word stays black', () {
      expect(
        SacredText.matchesIn('His son asked the lord of the house for bread'),
        isEmpty,
      );
    });

    test('the capitalized divine names are colored', () {
      expect(SacredText.matchesIn('the Son of God and the Holy Spirit'), [
        'Son',
        'God',
        'Holy Spirit',
      ]);
      expect(SacredText.matchesIn('Anaphora of Saint Basil'), ['Saint Basil']);
    });
  });

  test('highlighting can be turned off entirely', () {
    expect(SacredText.matchesIn(''), isEmpty);
  });
}
