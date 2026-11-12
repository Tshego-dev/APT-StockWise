import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ExpiryBadge extends StatelessWidget {
  final int daysUntilExpiry;

  const ExpiryBadge({super.key, required this.daysUntilExpiry});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    if (daysUntilExpiry < 0) {
      color = AppTheme.expiryColor;
      label = 'Expired';
    } else if (daysUntilExpiry <= 7) {
      color = AppTheme.expiryColor;
      label = '$daysUntilExpiry days';
    } else if (daysUntilExpiry <= 14) {
      color = AppTheme.warningColor;
      label = '$daysUntilExpiry days';
    } else if (daysUntilExpiry <= 30) {
      color = AppTheme.warningColor.withOpacity(0.8);
      label = '$daysUntilExpiry days';
    } else {
      color = AppTheme.safeColor;
      label = '${daysUntilExpiry}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
