import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../providers/water_provider.dart';

class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final water = ref.watch(waterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.olive),
            onPressed: () => _showGoalDialog(context, ref, water.goalMl),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress Header
            _buildProgressHeader(water),
            const SizedBox(height: 32),

            // Quick Add
            const Text('Quick Add', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            _buildQuickAddGrid(ref),
            const SizedBox(height: 32),

            // History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today\'s History', style: AppTextStyles.heading2),
                if (water.entries.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => ref.read(waterProvider.notifier).removeLastEntry(),
                    icon: const Icon(Icons.undo, size: 16, color: Colors.redAccent),
                    label: const Text('Undo', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (water.entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No water logged today yet',
                    style: TextStyle(color: Colors.white24)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: water.entries.reversed.length,
                itemBuilder: (context, index) {
                  final entry = water.entries.reversed.toList()[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.water_drop, color: AppColors.olive, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.ml.toInt()} ml',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(DateFormat('hh:mm a').format(entry.timestamp),
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(WaterState water) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.olive.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: water.progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.olive),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${water.todayMl.toInt()}',
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold)),
                  const Text('ml', style: TextStyle(color: AppColors.olive)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCol('Goal', '${water.goalMl.toInt()} ml'),
              _infoCol('Remaining', '${(water.goalMl - water.todayMl).clamp(0, water.goalMl).toInt()} ml'),
              _infoCol('Glasses', '${(water.todayMl / 250).toStringAsFixed(1)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildQuickAddGrid(WidgetRef ref) {
    final sizes = [150.0, 250.0, 330.0, 500.0];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: sizes.length,
      itemBuilder: (context, i) {
        final ml = sizes[i];
        return InkWell(
          onTap: () => ref.read(waterProvider.notifier).addWater(ml),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.olive.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.olive.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text('+ ${ml.toInt()} ml',
                style: const TextStyle(
                    color: AppColors.olive,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, double current) {
    final ctrl = TextEditingController(text: current.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Daily Water Goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'ml'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) {
                ref.read(waterProvider.notifier).setGoal(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}