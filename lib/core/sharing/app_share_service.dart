import 'package:share_plus/share_plus.dart';

import '../../features/liturgies/domain/liturgy.dart';

final class AppShareService {
  AppShareService._();

  static Future<ShareResult> shareApp() {
    return SharePlus.instance.share(
      ShareParams(
        title: 'ሥርዓተ ቅዳሴ',
        subject: 'Ethiopian Orthodox Liturgy',
        text:
            'የኢትዮጵያ ኦርቶዶክስ ሥርዓተ ቅዳሴን በግዕዝ፣ በአማርኛና '
            'በእንግሊዝኛ ያንብቡ።',
      ),
    );
  }

  static Future<ShareResult> shareLiturgy(Liturgy liturgy) {
    final amharicName = liturgy.nameAm.isEmpty ? liturgy.name : liturgy.nameAm;
    return SharePlus.instance.share(
      ShareParams(
        title: amharicName,
        subject: liturgy.name,
        text:
            '$amharicName\n'
            '${liturgy.name}\n\n'
            'በሥርዓተ ቅዳሴ መተግበሪያ ያንብቡ።',
      ),
    );
  }
}
