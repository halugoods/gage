import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/localization/gage_localization.dart';

class LanguageProvider extends ChangeNotifier {
  GageAppLanguage _language = GageAppLanguage.indonesia;
  static const String _prefLangKey = 'pref_app_language';

  GageAppLanguage get language => _language;
  String get currentCode => _language.code;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefLangKey);
      if (code != null) {
        _language = GageAppLanguage.fromCode(code);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(GageAppLanguage newLang) async {
    if (_language == newLang) return;
    _language = newLang;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLangKey, newLang.code);
    } catch (_) {}
  }

  String tr(String key) {
    return GageLocalization.get(key, _language.code);
  }
}

extension LanguageContextExtension on BuildContext {
  String tr(String key) {
    try {
      final provider = (this as dynamic).watch != null
          ? (this as dynamic).watch<LanguageProvider>()
          : null;
      if (provider != null) {
        return (provider as LanguageProvider).tr(key);
      }
    } catch (_) {}
    return GageLocalization.get(key, 'id');
  }
}
