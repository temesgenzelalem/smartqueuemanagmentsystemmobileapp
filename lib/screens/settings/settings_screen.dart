import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/locale_notifier.dart';
import '../../providers/theme_notifier.dart';

/// Settings screen that lets the user change language and theme mode.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsTitle),
      ),
      body: ListView(
        children: [
          // Language selection
          ListTile(
            title: Text(loc.languageLabel),
            subtitle: Text(locale.languageCode == 'en' ? loc.english : loc.amharic),
          ),
          RadioListTile<Locale>(
            title: Text(loc.english),
            value: const Locale('en'),
            groupValue: locale,
            onChanged: (value) async {
              if (value != null) {
                await ref.read(localeNotifierProvider.notifier).setLocale(value);
              }
            },
          ),
          RadioListTile<Locale>(
            title: Text(loc.amharic),
            value: const Locale('am'),
            groupValue: locale,
            onChanged: (value) async {
              if (value != null) {
                await ref.read(localeNotifierProvider.notifier).setLocale(value);
              }
            },
          ),
          const Divider(),
          // Theme selection
          ListTile(
            title: Text(loc.themeLabel),
            subtitle: Text(themeMode.name),
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.light),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (value) async {
              if (value != null) {
                await ref.read(themeNotifierProvider.notifier).setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.dark),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (value) async {
              if (value != null) {
                await ref.read(themeNotifierProvider.notifier).setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.system),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (value) async {
              if (value != null) {
                await ref.read(themeNotifierProvider.notifier).setThemeMode(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
