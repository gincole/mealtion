import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class TimelineSection extends StatelessWidget {
  const TimelineSection({
    super.key,
    required this.groupedMeals,
    required this.moodColor,
    required this.onOpenMealDetail,
    required this.onDeleteMeal,
  });

  final Map<String, List<Map<String, dynamic>>> groupedMeals;
  final Color Function(String) moodColor;
  final void Function(Map<String, dynamic>) onOpenMealDetail;
  final void Function(String mealId) onDeleteMeal;

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
                (meal) => _SwipeableTimelineItem(
                  meal: meal,
                  moodColor: moodColor,
                  onTap: () => onOpenMealDetail(meal),
                  onDelete: () => onDeleteMeal(meal['id'] as String),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SwipeableTimelineItem extends StatefulWidget {
  const _SwipeableTimelineItem({
    required this.meal,
    required this.moodColor,
    required this.onTap,
    required this.onDelete,
  });

  final Map<String, dynamic> meal;
  final Color Function(String) moodColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_SwipeableTimelineItem> createState() => _SwipeableTimelineItemState();
}

class _SwipeableTimelineItemState extends State<_SwipeableTimelineItem> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.meal['img'] as String?;
    
    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
          _dragOffset = _dragOffset.clamp(-80.0, 0.0);
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          if (_dragOffset < -50) {
            _dragOffset = -80;
          } else {
            _dragOffset = 0;
          }
        });
      },
      child: Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          children: [
            // Delete button background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.red,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Main card
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Container(
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
                        color: imageUrl == null ? AppColors.bg : null,
                        image: imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: imageUrl == null
                          ? const Center(child: Icon(Icons.restaurant, color: AppColors.textLight))
                          : null,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.meal['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.meal['time']} • ${widget.meal['location']}',
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
                        color: widget.moodColor(widget.meal['mood']),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
