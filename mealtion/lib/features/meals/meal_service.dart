import '../../data/api_client.dart';

class Meal {
  final String id;
  final String userId;
  final String title;
  final String? imageUrl;
  final bool hasImage;
  final String status; // 'green', 'yellow', 'red'
  final String date;   // e.g., '3 Dec 2025'
  final String time;   // e.g., '12:30'
  final String location;
  final DateTime? createdAt;

  Meal({
    required this.id,
    required this.userId,
    required this.title,
    this.imageUrl,
    this.hasImage = false,
    required this.status,
    required this.date,
    required this.time,
    required this.location,
    this.createdAt,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? '';
    final hasImage = json['hasImage'] == true;
    
    return Meal(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      imageUrl: hasImage ? ApiClient.mealImageUrl(id) : (json['imageUrl'] as String?),
      hasImage: hasImage,
      status: json['status'] ?? 'green',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  /// Convert to the format expected by existing widgets (Map<String, dynamic>)
  Map<String, dynamic> toWidgetMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'date': date,
      'location': location,
      'mood': status, // widgets use 'mood' instead of 'status'
      'img': imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=400',
    };
  }
}

class MealService {
  final ApiClient _api = ApiClient();

  Future<List<Meal>> getMeals({int limit = 50, int offset = 0}) async {
    final response = await _api.get('/meals?limit=$limit&offset=$offset');
    final items = (response['items'] as List?) ?? [];
    return items.map((item) => Meal.fromJson(item)).toList();
  }

  Future<Meal> createMeal({
    required String title,
    required String status,
    required String date,
    required String time,
    required String location,
    String? imageBase64,
    String? imageContentType,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'status': status,
      'date': date,
      'time': time,
      'location': location,
    };

    if (imageBase64 != null) {
      body['imageBase64'] = imageBase64;
      body['imageContentType'] = imageContentType ?? 'image/jpeg';
    }

    final response = await _api.post('/meals', body);
    return Meal.fromJson(response['meal']);
  }

  Future<void> deleteMeal(String id) async {
    await _api.delete('/meals/$id');
  }

  /// Get all meal dates and statuses for calendar dots (lightweight, no pagination)
  Future<List<MealCalendarEntry>> getMealsCalendar() async {
    final response = await _api.get('/meals/calendar');
    final items = (response['items'] as List?) ?? [];
    return items.map((item) => MealCalendarEntry.fromJson(item)).toList();
  }
}

/// Lightweight entry for calendar dots
class MealCalendarEntry {
  final String date;
  final String status;

  MealCalendarEntry({required this.date, required this.status});

  factory MealCalendarEntry.fromJson(Map<String, dynamic> json) {
    return MealCalendarEntry(
      date: json['date'] ?? '',
      status: json['status'] ?? 'green',
    );
  }

  /// Convert to widget-compatible map with 'mood' key
  Map<String, dynamic> toWidgetMap() {
    return {
      'date': date,
      'mood': status,
    };
  }
}

// Global singleton
final mealService = MealService();
