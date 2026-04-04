import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NutrientBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color? color;

  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '${value.toStringAsFixed(1)} / ${goal.toInt()} $unit',
                style: TextStyle(
                  color: color ?? AppColors.olive,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.olive),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
