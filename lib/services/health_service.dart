import 'package:health/health.dart';
import '../models/health_entry.dart';

class HealthService {
  final Health health = Health();

  Future<bool> requestPermissions() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.WEIGHT,
      HealthDataType.BODY_MASS_INDEX,
    ];
    // Modern health plugin uses a simplified authorization
    return await health.requestAuthorization(types);
  }

  Future<HealthEntry> fetchTodayHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    int steps = 0;
    double weight = 0;
    double bmi = 0;

    try {
      // Fetch steps using modern API
      steps = await health.getTotalStepsInInterval(midnight, now) ?? 0;

      // Fetch weight
      final weightData = await health.getHealthDataFromTypes(
        startTime: midnight.subtract(const Duration(days: 30)),
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );
      if (weightData.isNotEmpty) {
        weight = double.tryParse(weightData.last.value.toString()) ?? 0;
      }

      // Fetch BMI
      final bmiData = await health.getHealthDataFromTypes(
        startTime: midnight.subtract(const Duration(days: 30)),
        endTime: now,
        types: [HealthDataType.BODY_MASS_INDEX],
      );
      if (bmiData.isNotEmpty) {
        bmi = double.tryParse(bmiData.last.value.toString()) ?? 0;
      }
    } catch (e) {
      print("Error fetching health data: $e");
    }

    return HealthEntry(
      date: midnight,
      steps: steps,
      weight: weight,
      bodyMass: bmi,
    );
  }
}
