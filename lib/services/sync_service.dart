import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  final _firestore = FirebaseFirestore.instance;
  final _db = DatabaseService.instance;

  Future<void> syncToCloud(String uid) async {
    print('SYNC_UP: starting for $uid');
    final userDoc = _firestore.collection('users').doc(uid);

    final mealLogs = await _db.query('meal_logs');
    print('SYNC_UP: ${mealLogs.length} meal logs');
    for (final log in mealLogs) {
      await userDoc.collection('meal_logs').doc(log['id']).set(log);
    }

    final healthEntries = await _db.query('health_entries');
    for (final entry in healthEntries) {
      await userDoc.collection('health_entries').doc(entry['id']).set(entry);
    }

    final waterLogs = await _db.query('water_logs');
    for (final log in waterLogs) {
      await userDoc.collection('water_logs').doc(log['id']).set(log);
    }

    final settings = await _db.query('user_settings');
    for (final s in settings) {
      await userDoc.collection('user_settings').doc(s['key']).set(s);
    }

    print('SYNC_UP: done');
  }

  Future<void> syncFromCloud(String uid) async {
    print('SYNC_DOWN: starting for $uid');
    final userDoc = _firestore.collection('users').doc(uid);

    final mealLogs = await userDoc.collection('meal_logs').get();
    print('SYNC_DOWN: ${mealLogs.docs.length} meal logs found');
    for (final doc in mealLogs.docs) {
      await _db.insert('meal_logs', doc.data());
    }

    final healthEntries = await userDoc.collection('health_entries').get();
    for (final doc in healthEntries.docs) {
      await _db.insert('health_entries', doc.data());
    }

    final waterLogs = await userDoc.collection('water_logs').get();
    for (final doc in waterLogs.docs) {
      await _db.insert('water_logs', doc.data());
    }

    final settings = await userDoc.collection('user_settings').get();
    for (final doc in settings.docs) {
      await _db.insert('user_settings', doc.data());
    }

    print('SYNC_DOWN: done');
  }
}
