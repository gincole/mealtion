import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class HealthBreakdownBar extends StatelessWidget {
  const HealthBreakdownBar({
    super.key,
    this.healthyRatio = 0.50,
    this.moderateRatio = 0.25,
    this.heavyRatio = 0.25,
    this.isEmpty = false,
  });

  // Adjust the ratios here (should sum to 1.0)
  final double healthyRatio;   // e.g. 0.50 = 50%
  final double moderateRatio;  // e.g. 0.25 = 25%
  final double heavyRatio;     // e.g. 0.25 = 25%
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    // Show gray empty bar when no meals
    if (isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Center(
              child: Text(
                'No meals this week',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Legend(text: 'Heavy'),
              _Legend(text: 'Moderate'),
              _Legend(text: 'Healthy'),
            ],
          ),
        ],
      );
    }

    int flexFrom(double r) => (r * 100).round().clamp(1, 100);

    final healthyFlex = flexFrom(healthyRatio);
    final moderateFlex = flexFrom(moderateRatio);
    final heavyFlex = flexFrom(heavyRatio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Row(
              children: [
                Expanded(
                  flex: heavyFlex,
                  child: _Segment(
                    color: AppColors.red,
                    label: '${(heavyRatio * 100).round()}%',
                  ),
                ),
                Expanded(
                  flex: moderateFlex,
                  child: _Segment(
                    color: AppColors.yellow,
                    label: '${(moderateRatio * 100).round()}%',
                  ),
                ),
                Expanded(
                  flex: healthyFlex,
                  child: _Segment(
                    color: AppColors.green,
                    label: '${(healthyRatio * 100).round()}%',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Labels 
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _Legend(text: 'Heavy'),
            _Legend(text: 'Moderate'),
            _Legend(text: 'Healthy'),
          ],
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.45),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
      ),
    );
  }
}
