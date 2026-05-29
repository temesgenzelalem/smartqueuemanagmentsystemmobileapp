import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_notifier.dart';

/// Simple dropdown that lets the user select between English and Amharic.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    return DropdownButton<Locale>(
      value: locale,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: Locale('en'), child: Text('English')),
        DropdownMenuItem(value: Locale('am'), child: Text('አማርኛ')),
      ],
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          ref.read(localeNotifierProvider.notifier).setLocale(newLocale);
        }
      },
    );
  }
}
