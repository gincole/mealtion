import 'package:flutter/material.dart';
import '../../app/colors.dart';
import 'widgets/plan_card.dart';

class PlanView extends StatelessWidget {
  const PlanView({
    super.key,
    required this.plans,
    required this.onNewPlan,
  });

  final List<Map<String, dynamic>> plans;
  final VoidCallback onNewPlan;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Plan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                GestureDetector(
                  onTap: onNewPlan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16)],
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...plans.map((p) => PlanCard(plan: p)).toList(),
          ],
        ),
      ),
    );
  }
}
