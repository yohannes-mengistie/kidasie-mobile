import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_language.dart';

enum ReaderLanguage { all, geez, amharic, english }

final class ReaderPreferences {
  const ReaderPreferences({
    required this.appLanguage,
    required this.language,
    required this.textScale,
    required this.highlightSacredNames,
  });

  final AppLanguage appLanguage;
  final ReaderLanguage language;
  final double textScale;
  final bool highlightSacredNames;

  ReaderPreferences copyWith({
    AppLanguage? appLanguage,
    ReaderLanguage? language,
    double? textScale,
    bool? highlightSacredNames,
  }) {
    return ReaderPreferences(
      appLanguage: appLanguage ?? this.appLanguage,
      language: language ?? this.language,
      textScale: textScale ?? this.textScale,
      highlightSacredNames: highlightSacredNames ?? this.highlightSacredNames,
    );
  }
}

final class ReaderPreferencesStore {
  ReaderPreferencesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _appLanguageKey = 'app.language';
  static const String _languageKey = 'reader.language';
  static const String _textScaleKey = 'reader.text_scale';
  static const String _sacredNamesKey = 'reader.highlight_sacred_names';
  static const List<double> _allowedTextScales = [0.9, 1.0, 1.2, 1.4];

  final SharedPreferencesAsync _preferences;

  Future<ReaderPreferences> load() async {
    final storedAppLanguage = await _preferences.getString(_appLanguageKey);
    final storedLanguage = await _preferences.getString(_languageKey);
    final storedTextScale = await _preferences.getDouble(_textScaleKey);
    final highlightSacredNames = await _preferences.getBool(_sacredNamesKey);

    final textScale =
        storedTextScale != null && _allowedTextScales.contains(storedTextScale)
        ? storedTextScale
        : 1.0;

    return ReaderPreferences(
      appLanguage: _parseAppLanguage(storedAppLanguage),
      language: _parseLanguage(storedLanguage),
      textScale: textScale,
      highlightSacredNames: highlightSacredNames ?? true,
    );
  }

  Future<void> saveAppLanguage(AppLanguage language) {
    return _preferences.setString(_appLanguageKey, language.name);
  }

  Future<void> saveLanguage(ReaderLanguage language) {
    return _preferences.setString(_languageKey, language.name);
  }

  Future<void> saveTextScale(double textScale) {
    if (!_allowedTextScales.contains(textScale)) {
      throw ArgumentError.value(
        textScale,
        'textScale',
        'Unsupported text scale',
      );
    }

    return _preferences.setDouble(_textScaleKey, textScale);
  }

  Future<void> saveHighlightSacredNames(bool enabled) {
    return _preferences.setBool(_sacredNamesKey, enabled);
  }

  AppLanguage _parseAppLanguage(String? storedLanguage) {
    for (final language in AppLanguage.values) {
      if (language.name == storedLanguage) {
        return language;
      }
    }

    return AppLanguage.amharic;
  }

  ReaderLanguage _parseLanguage(String? storedLanguage) {
    for (final language in ReaderLanguage.values) {
      if (language.name == storedLanguage) {
        return language;
      }
    }

    return ReaderLanguage.all;
  }
}
