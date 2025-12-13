import 'package:flutter/material.dart';
import '../../app/colors.dart';
import '../../app/theme.dart';
import 'data/mock_data.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/splash.dart';
import 'widgets/meal_card.dart';
import 'widgets/timeline.dart';
import 'widgets/plan_card.dart';
import 'widgets/settings_item.dart';
import 'widgets/calendar_card.dart';
import 'modals/add_meal_modal.dart';
import 'modals/add_plan_modal.dart';
import 'modals/date_picker_modal.dart';
import 'modals/meal_detail_modal.dart';
import 'widgets/health_breakdown.dart';
import 'gallery_view.dart';
import 'plan_view.dart';
import 'settings_view.dart';
import 'widgets/health_breakdown.dart';


class MealtionHomePage extends StatefulWidget {
  const MealtionHomePage({super.key});

  @override
  State<MealtionHomePage> createState() => _MealtionHomePageState();
}

class _MealtionHomePageState extends State<MealtionHomePage> {
  int activeTab = 0;
  bool showSplash = true;
  String galleryViewMode = 'calendar'; // 'calendar' or 'grid'
  DateTime addMealDate = DateTime.now();

  final meals = mockMeals;
  final plans = mockPlans;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => showSplash = false);
    });
  }

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
      builder: (_) => const AddPlanModal(),
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

          if (showSplash) const SplashScreen(),
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
  });

  final List<Map<String, dynamic>> meals;
  final List<Map<String, dynamic>> plans;
  final void Function(Map<String, dynamic>) onOpenMealDetail;
  final Color Function(String) moodColor;

  @override
  Widget build(BuildContext context) {
    final currentPlan = plans.firstWhere(
      (p) => p['date'] == '3 Dec 2025',
      orElse: () => {},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (kept inline for now)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, Gincole',
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
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                    ],
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=100',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            CalendarCard(meals: meals),

            const SizedBox(height: 32),

            // Plan Today (kept inline; can extract later)
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
            if (currentPlan.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: (currentPlan['meals'] as List)
                      .map<Widget>(
                        (meal) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[300]),
                              const SizedBox(width: 12),
                              Text(
                                meal,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
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
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'ไม่มี Plan สำหรับวันนี้นะ กินให้เต็มที่! 😋',
                    style: TextStyle(fontSize: 14, color: AppColors.textLight),
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Weekly Health Breakdown (kept inline; can extract later)
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
              child: const HealthBreakdownBar(
                healthyRatio: 0.60,
                moderateRatio: 0.25,
                heavyRatio: 0.15,
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
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
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
    );
  }
}
