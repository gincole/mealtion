import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class TimelineSection extends StatelessWidget {
  const TimelineSection({
    super.key,
    required this.groupedMeals,
    required this.moodColor,
    required this.onOpenMealDetail,
  });

  final Map<String, List<Map<String, dynamic>>> groupedMeals;
  final Color Function(String) moodColor;
  final void Function(Map<String, dynamic>) onOpenMealDetail;

  @override
  Widget build(BuildContext context) {
    final dates = groupedMeals.keys.toList();

    return Column(
      children: dates.map((date) {
        final dayMeals = groupedMeals[date] ?? [];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              ...dayMeals.map(
                (meal) => _TimelineItem(
                  meal: meal,
                  moodColor: moodColor,
                  onTap: () => onOpenMealDetail(meal),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.meal,
    required this.moodColor,
    required this.onTap,
  });

  final Map<String, dynamic> meal;
  final Color Function(String) moodColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                image: DecorationImage(
                  image: NetworkImage(meal['img']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${meal['time']} • ${meal['location']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 8,
              height: double.infinity,
              decoration: BoxDecoration(
                color: moodColor(meal['mood']),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
