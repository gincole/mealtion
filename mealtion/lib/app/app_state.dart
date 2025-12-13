import 'package:flutter/foundation.dart';
import '../features/auth/auth_service.dart';
import '../features/meals/meal_service.dart';
import '../features/plans/plan_service.dart';

enum AppAuthState { loading, authenticated, unauthenticated }

class AppState extends ChangeNotifier {
  AppAuthState _authState = AppAuthState.loading;
  AppAuthState get authState => _authState;

  User? _user;
  User? get user => _user;

  List<Meal> _meals = [];
  List<Meal> get meals => _meals;

  List<Plan> _plans = [];
  List<Plan> get plans => _plans;

  bool _loadingMeals = false;
  bool get loadingMeals => _loadingMeals;

  bool _loadingPlans = false;
  bool get loadingPlans => _loadingPlans;

  String? _error;
  String? get error => _error;

  /// Initialize the app - check if user is logged in
  Future<void> init() async {
    _authState = AppAuthState.loading;
    notifyListeners();

    try {
      final user = await authService.tryAutoLogin();
      if (user != null) {
        _user = user;
        _authState = AppAuthState.authenticated;
        // Load data after successful auto-login
        await Future.wait([loadMeals(), loadPlans()]);
      } else {
        _authState = AppAuthState.unauthenticated;
      }
    } catch (e) {
      _authState = AppAuthState.unauthenticated;
    }
    notifyListeners();
  }

  /// Called after successful login/register
  Future<void> onAuthenticated() async {
    _user = authService.currentUser;
    _authState = AppAuthState.authenticated;
    notifyListeners();

    await Future.wait([loadMeals(), loadPlans()]);
  }

  /// Logout
  Future<void> logout() async {
    await authService.logout();
    _user = null;
    _meals = [];
    _plans = [];
    _authState = AppAuthState.unauthenticated;
    notifyListeners();
  }

  /// Load meals from API
  Future<void> loadMeals() async {
    _loadingMeals = true;
    _error = null;
    notifyListeners();

    try {
      _meals = await mealService.getMeals();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingMeals = false;
      notifyListeners();
    }
  }

  /// Load plans from API
  Future<void> loadPlans() async {
    _loadingPlans = true;
    _error = null;
    notifyListeners();

    try {
      _plans = await planService.getPlans();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingPlans = false;
      notifyListeners();
    }
  }

  /// Add a new meal
  Future<void> addMeal({
    required String title,
    required String status,
    required String date,
    required String time,
    required String location,
    String? imageBase64,
    String? imageContentType,
  }) async {
    try {
      final meal = await mealService.createMeal(
        title: title,
        status: status,
        date: date,
        time: time,
        location: location,
        imageBase64: imageBase64,
        imageContentType: imageContentType,
      );
      _meals.insert(0, meal); // Add to beginning of list
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Add a new plan
  Future<void> addPlan({
    required String title,
    required String date,
    required String time,
    required String mealTime,
    required String status,
  }) async {
    try {
      final plan = await planService.createPlan(
        title: title,
        date: date,
        time: time,
        mealTime: mealTime,
        status: status,
      );
      _plans.add(plan);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a plan by ID
  Future<void> deletePlan(String planId) async {
    try {
      await planService.deletePlan(planId);
      _plans.removeWhere((p) => p.id == planId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a meal by ID
  Future<void> deleteMeal(String mealId) async {
    try {
      await mealService.deleteMeal(mealId);
      _meals.removeWhere((m) => m.id == mealId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Get meals as widget-compatible maps
  List<Map<String, dynamic>> get mealsForWidgets {
    return _meals.map((m) => m.toWidgetMap()).toList();
  }

  /// Get plans as widget-compatible maps (grouped format for UI)
  List<Map<String, dynamic>> get plansForWidgets {
    // Group plans by date for the existing UI format
    final grouped = <String, List<Map<String, dynamic>>>{};
    final dateLabels = <String, String>{};
    final dateParsed = <String, DateTime?>{};

    for (final plan in _plans) {
      final date = plan.date;
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add({
        'id': plan.id,
        'title': plan.title,
        'time': plan.time,
        'mealTime': plan.mealTime,
        'status': plan.status,
        'display': plan.title,
      });

      // Determine day label
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final planDate = _parseDate(date);
      dateParsed[date] = planDate;

      if (planDate != null) {
        if (_isSameDay(planDate, today)) {
          dateLabels[date] = 'Today';
        } else if (_isSameDay(planDate, tomorrow)) {
          dateLabels[date] = 'Tomorrow';
        } else {
          dateLabels[date] = _formatDate(planDate);
        }
      } else {
        dateLabels[date] = date;
      }
    }

    // Sort each group's items by time
    for (final items in grouped.values) {
      items.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
    }

    // Sort entries by parsed date
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final dateA = dateParsed[a.key];
        final dateB = dateParsed[b.key];
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

    return sortedEntries.map((e) {
      return {
        'id': e.key,
        'day': dateLabels[e.key] ?? e.key,
        'date': e.key,
        'meals': e.value.map((m) => m['display'] as String).toList(),
        'planItems': e.value, // Individual plan items with IDs
      };
    }).toList();
  }

  /// Get today's plan for home view
  Map<String, dynamic>? get todayPlan {
    final today = DateTime.now();
    final todayPlans = _plans.where((p) {
      final planDate = _parseDate(p.date);
      return planDate != null && _isSameDay(planDate, today);
    }).toList();

    if (todayPlans.isEmpty) return null;

    // Sort by time
    todayPlans.sort((a, b) => a.time.compareTo(b.time));

    final planItems = todayPlans.map((p) => {
      'id': p.id,
      'title': p.title,
      'time': p.time,
      'mealTime': p.mealTime,
      'status': p.status,
      'display': p.title,
    }).toList();

    return {
      'id': 'today',
      'day': 'Today',
      'date': _formatDate(today),
      'meals': todayPlans.map((p) => p.title).toList(),
      'planItems': planItems,
    };
  }

  /// Calculate health breakdown from meals (last 7 days)
  Map<String, double> get weeklyHealthBreakdown {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekMeals = _meals.where((m) {
      final mealDate = _parseDate(m.date);
      return mealDate != null && mealDate.isAfter(weekAgo);
    }).toList();

    if (weekMeals.isEmpty) {
      return {'healthy': 0.33, 'moderate': 0.34, 'heavy': 0.33};
    }

    int green = 0, yellow = 0, red = 0;
    for (final m in weekMeals) {
      switch (m.status) {
        case 'green':
          green++;
          break;
        case 'yellow':
          yellow++;
          break;
        case 'red':
          red++;
          break;
      }
    }

    final total = green + yellow + red;
    return {
      'healthy': total > 0 ? green / total : 0.33,
      'moderate': total > 0 ? yellow / total : 0.34,
      'heavy': total > 0 ? red / total : 0.33,
    };
  }

  // Helper methods
  DateTime? _parseDate(String date) {
    // Try parsing "13 Dec 2025" format
    final parts = date.split(' ');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = _monthFromShort(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    // Try parsing ISO format
    return DateTime.tryParse(date);
  }

  int? _monthFromShort(String m) {
    const short = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    return short[m];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
