import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/brand_title.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: BrandTitle(title: loc.aboutTitle, showLogo: false),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/tsehay_logo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, size: 80, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart Queue Management System',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              loc.appDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              loc.devInfo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 16),
            _buildDevInfo(Icons.person, 'Temesgen Zelalem'),
            _buildDevInfo(Icons.email, 'temesgenzelalem167@gmail.com'),
            _buildDevInfo(Icons.phone, '+251 932 638 178'),
            const SizedBox(height: 40),
            Text(
              loc.copyright,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
