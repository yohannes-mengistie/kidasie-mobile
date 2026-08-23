import 'package:flutter/widgets.dart';

enum AppLanguage { amharic, english }

extension AppLanguageUi on AppLanguage {
  bool get isEnglish => this == AppLanguage.english;

  Locale get locale => Locale(isEnglish ? 'en' : 'am');

  String text({required String amharic, required String english}) {
    return isEnglish ? english : amharic;
  }
}
