import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/health_entry.dart';

class HealthService {
  final Health health = Health();
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.body.read',
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      print('Google Sign In Error: $error');
      return null;
    }
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<bool> requestPermissions() async {
    try {
      // For Android 13+, activity recognition is vital for Health Connect
      await [
        Permission.activityRecognition,
      ].request();

      final types = [
        HealthDataType.STEPS,
        HealthDataType.WEIGHT,
        HealthDataType.BODY_MASS_INDEX,
      ];
      
      // Request authorization (this triggers the Health Connect / Google Fit UI)
      return await health.requestAuthorization(types);
    } catch (e) {
      print('Error requesting health permissions: $e');
      return false;
    }
  }

  Future<HealthEntry> fetchTodayHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    int steps = 0;
    double weight = 0;
    double bmi = 0;

    try {
      // 1. Fetch steps
      steps = await health.getTotalStepsInInterval(midnight, now) ?? 0;

      // 2. Fetch weight & BMI from the last 30 days
      final data = await health.getHealthDataFromTypes(
        startTime: midnight.subtract(const Duration(days: 30)),
        endTime: now,
        types: [HealthDataType.WEIGHT, HealthDataType.BODY_MASS_INDEX],
      );

      if (data.isNotEmpty) {
        // Find most recent weight
        final weights = data.where((d) => d.type == HealthDataType.WEIGHT).toList();
        if (weights.isNotEmpty) {
          weights.sort((a, b) => b.dateTo.compareTo(a.dateTo));
          weight = double.tryParse(weights.first.value.toString()) ?? 0;
        }

        // Find most recent BMI
        final bmis = data.where((d) => d.type == HealthDataType.BODY_MASS_INDEX).toList();
        if (bmis.isNotEmpty) {
          bmis.sort((a, b) => b.dateTo.compareTo(a.dateTo));
          bmi = double.tryParse(bmis.first.value.toString()) ?? 0;
        }
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