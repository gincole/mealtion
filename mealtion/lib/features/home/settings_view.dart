import 'package:flutter/material.dart';
import '../../app/colors.dart';
import 'widgets/settings_item.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=100',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Gincole', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      SizedBox(height: 4),
                      Text('gincole@email.com', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SettingsItem(icon: Icons.person, title: 'Account'),
            SettingsItem(icon: Icons.lock, title: 'Privacy'),
            SettingsItem(icon: Icons.logout, title: 'Log out'),
          ],
        ),
      ),
    );
  }
}
