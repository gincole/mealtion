import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.moodColor,
    required this.onTap,
  });

  final Map<String, dynamic> meal;
  final Color Function(String mood) moodColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Fixed image height prevents layout overflow
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        meal['img'] ?? 'https://via.placeholder.com/400x300?text=No+Image',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.bg,
                          child: const Center(
                            child: Icon(Icons.restaurant, color: AppColors.textLight, size: 40),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 16,
                      child: Container(
                        width: 32,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: moodColor(meal['mood']),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Text section uses Expanded to avoid overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${meal['date']} • ${meal['time']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
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
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              meal['location'],
                              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
