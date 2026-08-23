import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/liturgies/domain/liturgy.dart';

final class AppShareService {
  AppShareService._();

  static const MethodChannel _appChannel = MethodChannel(
    'com.yohannes.kidasie/app',
  );

  static Future<ShareResult> shareApp() async {
    if (!Platform.isAndroid) {
      return _shareAppDescription();
    }

    final installedApkPath = await _appChannel.invokeMethod<String>(
      'getInstalledApkPath',
    );
    if (installedApkPath == null || installedApkPath.isEmpty) {
      throw StateError('The installed APK path is unavailable.');
    }

    final installedApk = File(installedApkPath);
    if (!await installedApk.exists()) {
      throw StateError('The installed APK file does not exist.');
    }

    final temporaryDirectory = await getTemporaryDirectory();
    final sharedApk = File('${temporaryDirectory.path}/Kidasie.apk');
    await installedApk.copy(sharedApk.path);

    return SharePlus.instance.share(
      ShareParams(
        title: 'ሥርዓተ ቅዳሴ',
        subject: 'Ethiopian Orthodox Liturgy APK',
        text:
            'የሥርዓተ ቅዳሴ መተግበሪያ።\n'
            'Ethiopian Orthodox Liturgy application.',
        files: [
          XFile(
            sharedApk.path,
            mimeType: 'application/vnd.android.package-archive',
          ),
        ],
        fileNameOverrides: const ['Kidasie.apk'],
      ),
    );
  }

  static Future<ShareResult> _shareAppDescription() {
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
            '$amharicName\n${liturgy.name}\n\nበሥርዓተ ቅዳሴ መተግበሪያ ያንብቡ።',
      ),
    );
  }
}
