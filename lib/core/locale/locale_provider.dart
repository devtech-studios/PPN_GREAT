import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LocaleProvider — จัดการการสลับภาษาและจดจำค่าภาษาที่เลือกไว้
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'ppn_locale';
  
  // ค่าเริ่มต้น: ภาษาไทย
  Locale _locale = const Locale('th');
  
  Locale get locale => _locale;
  
  bool get isThai => _locale.languageCode == 'th';
  bool get isEnglish => _locale.languageCode == 'en';

  /// โหลดค่าภาษาที่เคยเลือกไว้จาก SharedPreferences
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_prefKey);
    if (savedLang != null) {
      _locale = Locale(savedLang);
      notifyListeners();
    }
  }

  /// สลับภาษา TH ⇄ EN
  Future<void> toggleLocale() async {
    _locale = isThai ? const Locale('en') : const Locale('th');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _locale.languageCode);
    notifyListeners();
  }

  /// ตั้งค่าภาษาโดยตรง
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
    notifyListeners();
  }
}

/// Global instance for LocaleProvider
final localeProvider = LocaleProvider();
