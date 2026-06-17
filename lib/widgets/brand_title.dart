import 'package:flutter/material.dart';

class BrandTitle extends StatelessWidget {
  final String title;
  final bool showLogo;

  const BrandTitle({super.key, required this.title, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          Image.asset(
            'assets/tsehay_logo.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance, size: 24, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
