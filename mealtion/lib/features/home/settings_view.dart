import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/colors.dart';
import '../../app/app_state.dart';
import 'widgets/settings_item.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            const SizedBox(height: 16),

            // Profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SettingsItem(icon: Icons.person, title: 'Account'),
            SettingsItem(icon: Icons.lock, title: 'Privacy'),
            SettingsItem(
              icon: Icons.logout,
              title: 'Log out',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await context.read<AppState>().logout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
