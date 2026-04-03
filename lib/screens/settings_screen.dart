import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/health_provider.dart';
import 'profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SettingsHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.accent),
            title: const Text('Profile & Dietary Settings', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Manage allergies and profile info', style: AppTextStyles.caption),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          const Divider(color: Colors.white10),
          const _SettingsHeader(title: 'Health & Data'),
          ListTile(
            leading: const Icon(Icons.sync, color: AppColors.accent),
            title: const Text('Sync with Google Fit', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Fetch latest steps and weight data', style: AppTextStyles.caption),
            onTap: () async {
              await ref.read(healthProvider.notifier).syncWithGoogleFit();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Synced with Google Fit')),
                );
              }
            },
          ),
          const Divider(color: Colors.white10),
          const _SettingsHeader(title: 'About'),
          const ListTile(
            title: Text('App Version', style: TextStyle(color: Colors.white)),
            trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String title;
  const _SettingsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
