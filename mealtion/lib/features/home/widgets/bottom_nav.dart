import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.activeIndex,
    required this.onChange,
  });

  final int activeIndex;
  final void Function(int) onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(icon: Icons.home, label: 'Home', index: 0, activeIndex: activeIndex, onChange: onChange),
              _NavItem(icon: Icons.image, label: 'Gallery', index: 1, activeIndex: activeIndex, onChange: onChange),
              const SizedBox(width: 64),
              _NavItem(icon: Icons.calendar_today, label: 'Plan', index: 2, activeIndex: activeIndex, onChange: onChange),
              _NavItem(icon: Icons.settings, label: 'Setting', index: 3, activeIndex: activeIndex, onChange: onChange),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.activeIndex,
    required this.onChange,
  });

  final IconData icon;
  final String label;
  final int index;
  final int activeIndex;
  final void Function(int) onChange;

  @override
  Widget build(BuildContext context) {
    final isActive = activeIndex == index;
    return GestureDetector(
      onTap: () => onChange(index),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isActive ? AppColors.primary : const Color(0xFFD1D5DB)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isActive ? AppColors.primary : const Color(0xFFD1D5DB)),
            ),
          ],
        ),
      ),
    );
  }
}
