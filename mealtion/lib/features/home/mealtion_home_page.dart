import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/colors.dart';
import '../../app/app_state.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/meal_card.dart';
import 'widgets/calendar_card.dart';
import 'modals/add_meal_modal.dart';
import 'modals/date_picker_modal.dart';
import 'modals/meal_detail_modal.dart';
import 'widgets/health_breakdown.dart';
import 'gallery_view.dart';
import 'plan_view.dart';
import 'settings_view.dart';


class MealtionHomePage extends StatefulWidget {
  const MealtionHomePage({super.key});

  @override
  State<MealtionHomePage> createState() => _MealtionHomePageState();
}

class _MealtionHomePageState extends State<MealtionHomePage> {
  int activeTab = 0;
  String galleryViewMode = 'calendar'; // 'calendar' or 'grid'
  DateTime addMealDate = DateTime.now();

  Color moodColor(String mood) {
    switch (mood) {
      case 'green':
        return AppColors.green;
      case 'yellow':
        return AppColors.yellow;
      case 'red':
        return AppColors.red;
      default:
        return Colors.grey;
    }
  }

  String moodLabel(String mood) {
    switch (mood) {
      case 'green':
        return 'Healthy';
      case 'yellow':
        return 'Moderate';
      case 'red':
        return 'Cheat';
      default:
        return '';
    }
  }

  void openAddMealModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMealModal(
        date: addMealDate,
        onPickDate: openDatePickerModal,
        moodColor: moodColor,
      ),
    );
  }

  void openAddPlanModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMealModal(
        date: addMealDate,
        onPickDate: openDatePickerModal,
        moodColor: moodColor,
        isPlan: true,
      ),
    );
  }

  void openDatePickerModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => DatePickerModal(
        selected: addMealDate,
        onSelect: (d) => setState(() => addMealDate = d),
      ),
    );
  }

  void openMealDetailModal(Map<String, dynamic> meal) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => MealDetailModal(
        meal: meal,
        moodColor: moodColor,
        moodLabel: moodLabel,
        onDelete: () async {
          final appState = context.read<AppState>();
          await appState.deleteMeal(meal['id']);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final meals = appState.mealsForWidgets;
    final plans = appState.plansForWidgets;
    final calendarData = appState.calendarForWidgets;
    final isLoading = appState.loadingMeals || appState.loadingPlans;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            top: true,     // protects iPhone notch / dynamic island
            bottom: false, // bottom nav already handled
            child: Padding(
              padding: const EdgeInsets.only(top: 60), // adjust top spacing
              child: IndexedStack(
                index: activeTab,
                children: [
                  _HomeView(
                    meals: meals,
                    calendarData: calendarData,
                    plans: plans,
                    onOpenMealDetail: openMealDetailModal,
                    moodColor: moodColor,
                    onRefresh: () async {
                      await Future.wait([
                        appState.loadMeals(),
                        appState.loadPlans(),
                        appState.loadCalendar(),
                      ]);
                    },
                  ),
                  GalleryView(
                    meals: meals,
                    viewMode: galleryViewMode,
                    onChangeMode: (m) => setState(() => galleryViewMode = m),
                    onOpenMealDetail: openMealDetailModal,
                    moodColor: moodColor,
                    onDeleteMeal: (mealId) async {
                      await appState.deleteMeal(mealId);
                    },
                    availableMonths: appState.availableMonths,
                    selectedMonth: appState.selectedMonth,
                    onMonthSelected: (month) async {
                      await appState.setSelectedMonth(month);
                    },
                  ),
                  PlanView(
                    plans: plans,
                    onNewPlan: openAddPlanModal,
                    onDeletePlan: (planId) async {
                      await appState.deletePlan(planId);
                    },
                  ),
                  const SettingsView(),
                ],
              ),
            ),
          ),


          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: activeTab,
              onChange: (i) => setState(() => activeTab = i),
            ),
          ),

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: openAddMealModal,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 32, color: Colors.white),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.meals,
    required this.calendarData,
    required this.plans,
    required this.onOpenMealDetail,
    required this.moodColor,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> meals;
  final List<Map<String, dynamic>> calendarData;
  final List<Map<String, dynamic>> plans;
  final void Function(Map<String, dynamic>) onOpenMealDetail;
  final Color Function(String) moodColor;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final todayPlan = appState.todayPlan;
    final breakdown = appState.weeklyHealthBreakdown;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.name ?? 'there'}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How was your meal?',
                        style: TextStyle(fontSize: 14, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                      ],
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              CalendarCard(meals: calendarData),

              const SizedBox(height: 32),

              // Plan Today
              Row(
                children: [
                  Text(
                    'Your Plan ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (todayPlan != null && (todayPlan['planItems'] as List?)?.isNotEmpty == true)
                _TodayPlanCard(
                  planItems: (todayPlan['planItems'] as List).cast<Map<String, dynamic>>(),
                  onDelete: () async {
                    final planItems = (todayPlan['planItems'] as List).cast<Map<String, dynamic>>();
                    for (final item in planItems) {
                      await appState.deletePlan(item['id'] as String);
                    }
                  },
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    border: Border.all(color: Colors.grey[200]!, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No plans yet. Tap New to create your first plan!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textLight),
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Weekly Health Breakdown
              Row(
                children: [
                  Text(
                    'Weekly ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    'Health Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: HealthBreakdownBar(
                  healthyRatio: breakdown['healthy'] ?? 0.0,
                  moderateRatio: breakdown['moderate'] ?? 0.0,
                  heavyRatio: breakdown['heavy'] ?? 0.0,
                  isEmpty: breakdown['empty'] == 1.0,
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Text(
                    'Your Latest ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    'Meal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (meals.isEmpty)
                Container(
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
              else
                SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: meals.length > 6 ? 6 : meals.length,
                    itemBuilder: (_, i) => MealCard(
                      meal: meals[i],
                      moodColor: moodColor,
                      onTap: () => onOpenMealDetail(meals[i]),
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

class _TodayPlanCard extends StatefulWidget {
  const _TodayPlanCard({
    required this.planItems,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> planItems;
  final VoidCallback onDelete;

  @override
  State<_TodayPlanCard> createState() => _TodayPlanCardState();
}

class _TodayPlanCardState extends State<_TodayPlanCard> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
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
      child: Stack(
        children: [
          // Delete button background (visible when swiped)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
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
          // Main card content
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: widget.planItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.grey[300]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['title'] as String? ?? item['display'] as String? ?? '',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
