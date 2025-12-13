import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class MealDetailModal extends StatelessWidget {
  const MealDetailModal({
    super.key,
    required this.meal,
    required this.moodColor,
    required this.moodLabel,
    required this.onDelete,
  });

  final Map<String, dynamic> meal;
  final Color Function(String) moodColor;
  final String Function(String) moodLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = meal['img'] as String?;
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.bg,
                            child: const Center(
                              child: Icon(Icons.restaurant, color: AppColors.textLight, size: 60),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.bg,
                          child: const Center(
                            child: Icon(Icons.restaurant, color: AppColors.textLight, size: 60),
                          ),
                        ),
                ),
                // Type point on left
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: moodColor(meal['mood'])),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          moodLabel(meal['mood']),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain),
                        ),
                      ],
                    ),
                  ),
                ),
                // Delete button on right
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['title'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${meal['date']} • ${meal['time']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          meal['location'],
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
