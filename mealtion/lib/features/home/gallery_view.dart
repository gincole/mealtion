import 'package:flutter/material.dart';
import '../../app/colors.dart';
import 'widgets/timeline.dart';

class GalleryView extends StatelessWidget {
  const GalleryView({
    super.key,
    required this.meals,
    required this.viewMode,
    required this.onChangeMode,
    required this.onOpenMealDetail,
    required this.moodColor,
    required this.onDeleteMeal,
  });

  final List<Map<String, dynamic>> meals;
  final String viewMode; // 'calendar' (timeline) or 'grid'
  final void Function(String) onChangeMode;
  final void Function(Map<String, dynamic>) onOpenMealDetail;
  final Color Function(String) moodColor;
  final void Function(String mealId) onDeleteMeal;

  Map<String, List<Map<String, dynamic>>> _groupMealsByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final meal in meals) {
      final date = meal['date'] as String;
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(meal);
    }
    
    // Sort each date's meals by time (earliest first)
    for (final date in grouped.keys) {
      grouped[date]!.sort((a, b) {
        final timeA = a['time'] as String? ?? '00:00';
        final timeB = b['time'] as String? ?? '00:00';
        return timeA.compareTo(timeB);
      });
    }
    
    // Sort dates (latest first) and return as LinkedHashMap to preserve order
    final sortedDates = grouped.keys.toList()..sort((a, b) {
      final dateA = _parseDate(a);
      final dateB = _parseDate(b);
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA); // Latest first
    });
    
    final sortedGrouped = <String, List<Map<String, dynamic>>>{};
    for (final date in sortedDates) {
      sortedGrouped[date] = grouped[date]!;
    }
    return sortedGrouped;
  }

  DateTime? _parseDate(String date) {
    // Parse "13 Dec 2025" format
    final parts = date.split(' ');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = _monthFromShort(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  int? _monthFromShort(String short) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    return months[short];
  }

  @override
  Widget build(BuildContext context) {
    final groupedMeals = _groupMealsByDate();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gallery',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                Row(
                  children: [
                    _ModeButton(
                      label: 'Timeline',
                      active: viewMode == 'calendar',
                      onTap: () => onChangeMode('calendar'),
                    ),
                    const SizedBox(width: 8),
                    _ModeButton(
                      label: 'Grid',
                      active: viewMode == 'grid',
                      onTap: () => onChangeMode('grid'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (meals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No meals yet. Tap + to add your first meal!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textLight),
                  ),
                ),
              )
            else if (viewMode == 'grid')
              _GridSection(
                meals: meals,
                onOpenMealDetail: onOpenMealDetail,
              )
            else
              TimelineSection(
                groupedMeals: groupedMeals,
                moodColor: moodColor,
                onOpenMealDetail: onOpenMealDetail,
                onDeleteMeal: onDeleteMeal,
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}

class _GridSection extends StatelessWidget {
  const _GridSection({
    required this.meals,
    required this.onOpenMealDetail,
  });

  final List<Map<String, dynamic>> meals;
  final void Function(Map<String, dynamic>) onOpenMealDetail;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: meals.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final meal = meals[i];
        final imageUrl = meal['img'] as String?;
        return GestureDetector(
          onTap: () => onOpenMealDetail(meal),
          child: Container(
            decoration: BoxDecoration(
              color: imageUrl != null ? Colors.white : AppColors.bg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? const Center(child: Icon(Icons.restaurant, color: AppColors.textLight))
                : null,
          ),
        );
      },
    );
  }
}
