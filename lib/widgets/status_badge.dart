import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _background {
    switch (status.toLowerCase()) {
      case 'waiting':
        return const Color(0xFFF1F5F9);
      case 'pending':
      case 'called':
        return const Color(0xFFFEF3C7);
      case 'processing':
        return const Color(0xFFFED7AA);
      case 'completed':
        return const Color(0xFFDCFCE7);
      default:
        return Colors.grey.shade200;
    }
  }

  Color get _foreground {
    switch (status.toLowerCase()) {
      case 'waiting':
        return const Color(0xFF64748B);
      case 'pending':
      case 'called':
        return const Color(0xFF92400E);
      case 'processing':
        return const Color(0xFFC2410C);
      case 'completed':
        return const Color(0xFF166534);
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _foreground,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
