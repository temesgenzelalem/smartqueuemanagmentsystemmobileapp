import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [StateNotifier] that holds the current app [Locale] and persists it.
class LocaleNotifier extends StateNotifier<Locale> {
  static const _prefKey = 'selected_locale';

  LocaleNotifier() : super(const Locale('en')) {
    _loadFromPrefs();
  }

  // Load saved locale from SharedPreferences (fallback to system locale).
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null) {
      state = Locale(code);
    }
  }

  /// Change the locale and persist the selection.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }
}

// Expose the notifier via a Riverpod provider.
final localeNotifierProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
