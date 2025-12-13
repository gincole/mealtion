import '../../data/api_client.dart';

class Plan {
  final String id;
  final String userId;
  final String title;
  final String date;     // e.g., '2025-12-13' or '13 Dec 2025'
  final String time;     // e.g., '08:00', '12:30'
  final String mealTime; // e.g., 'Breakfast', 'Lunch', 'Dinner'
  final String status;   // 'green', 'yellow', 'red'

  Plan({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.time,
    required this.mealTime,
    required this.status,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      mealTime: json['mealTime'] ?? '',
      status: json['status'] ?? 'green',
    );
  }

  /// Convert to the format expected by existing widgets
  Map<String, dynamic> toWidgetMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'mealTime': mealTime,
      'status': status,
    };
  }
}

class PlanService {
  final ApiClient _api = ApiClient();

  Future<List<Plan>> getPlans({String? date}) async {
    String path = '/plans';
    if (date != null) {
      path += '?date=$date';
    }
    final response = await _api.get(path);
    final items = (response['items'] as List?) ?? [];
    return items.map((item) => Plan.fromJson(item)).toList();
  }

  Future<Plan> createPlan({
    required String title,
    required String date,
    required String time,
    required String mealTime,
    required String status,
  }) async {
    final response = await _api.post('/plans', {
      'title': title,
      'date': date,
      'time': time,
      'mealTime': mealTime,
      'status': status,
    });

    // The API returns the inserted ID
    return Plan(
      id: response['id'] ?? '',
      userId: '',
      title: title,
      date: date,
      time: time,
      mealTime: mealTime,
      status: status,
    );
  }

  Future<void> deletePlan(String id) async {
    await _api.delete('/plans/$id');
  }
}

// Global singleton
final planService = PlanService();
