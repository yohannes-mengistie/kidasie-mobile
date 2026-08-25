import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_liturgy/features/liturgies/domain/liturgy.dart';

void main() {
  test('decodes text and audio availability from the catalog', () {
    final liturgy = Liturgy.fromJson({
      'id': 14,
      'slug': 'st-jacob-of-serough',
      'name': 'Anaphora of St. Jacob of Serough',
      'name_am': 'የቅዱስ ያዕቆብ ዘሥሩግ ቅዳሴ',
      'content_version': 2,
      'has_content': false,
      'audio': {
        'url': 'https://media.example.org/st-jacob.mp3',
        'duration_ms': 1000,
        'size_bytes': 1024,
        'mime_type': 'audio/mpeg',
        'sha256':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      },
    });

    expect(liturgy.hasContent, isFalse);
    expect(liturgy.hasAudio, isTrue);
    expect(liturgy.audio?.durationMs, 1000);
  });
}
