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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final meals = appState.mealsForWidgets;
    final plans = appState.plansForWidgets;

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
                    plans: plans,
                    onOpenMealDetail: openMealDetailModal,
                    moodColor: moodColor,
                    onRefresh: () async {
                      await Future.wait([
                        appState.loadMeals(),
                        appState.loadPlans(),
                      ]);
                    },
                  ),
                  GalleryView(
                    meals: meals,
                    viewMode: galleryViewMode,
                    onChangeMode: (m) => setState(() => galleryViewMode = m),
                    onOpenMealDetail: openMealDetailModal,
                    moodColor: moodColor,
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
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.meals,
    required this.plans,
    required this.onOpenMealDetail,
    required this.moodColor,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> meals;
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

              CalendarCard(meals: meals),

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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: (todayPlan['planItems'] as List)
                        .map<Widget>(
                          (item) => _SwipeableTodayPlanItem(
                            item: item as Map<String, dynamic>,
                            onDelete: () async {
                              await appState.deletePlan(item['id'] as String);
                            },
                          ),
                        )
                        .toList(),
                  ),
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
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Weekly ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const TextSpan(
                      text: 'Health Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
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
                  healthyRatio: breakdown['healthy'] ?? 0.33,
                  moderateRatio: breakdown['moderate'] ?? 0.34,
                  heavyRatio: breakdown['heavy'] ?? 0.33,
                ),
              ),

              const SizedBox(height: 32),

              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Your latest ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                    ),
                    TextSpan(
                      text: 'meal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
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

class _SwipeableTodayPlanItem extends StatefulWidget {
  const _SwipeableTodayPlanItem({
    required this.item,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  @override
  State<_SwipeableTodayPlanItem> createState() => _SwipeableTodayPlanItemState();
}

class _SwipeableTodayPlanItemState extends State<_SwipeableTodayPlanItem>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDeleting = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: -50.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleCheck() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    
    await _animController.forward();
    widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (_isDeleting) return;
          setState(() {
            _dragOffset += details.delta.dx;
            _dragOffset = _dragOffset.clamp(-60.0, 0.0);
          });
        },
        onHorizontalDragEnd: (details) {
          if (_isDeleting) return;
          setState(() {
            if (_dragOffset < -40) {
              _dragOffset = -60;
            } else {
              _dragOffset = 0;
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Stack(
            children: [
              // Delete button background
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _handleCheck,
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _handleCheck,
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.item['display'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
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
      ),
    );
  }
}
