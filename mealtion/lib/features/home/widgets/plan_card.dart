import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class PlanCard extends StatefulWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.onDeletePlan,
  });

  final Map<String, dynamic> plan;
  final void Function(String planId) onDeletePlan;

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  double _dragOffset = 0;

  void _deleteAllPlans() {
    final planItems = (widget.plan['planItems'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final item in planItems) {
      widget.onDeletePlan(item['id'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planItems = (widget.plan['planItems'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return GestureDetector(
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
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            // Delete button background (visible when swiped)
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
                      onTap: _deleteAllPlans,
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
            // Main card content
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.plan['day'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.plan['date'],
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...planItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.grey[300]),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['title'] as String? ?? item['display'] as String? ?? '',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if ((item['time'] as String?)?.isNotEmpty == true)
                              Text(
                                item['time'] as String,
                                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              ),
                          ],
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
