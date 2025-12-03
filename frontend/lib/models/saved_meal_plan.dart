class SavedMealPlan {
  final String id;
  final String planName;
  final DateTime createdAt;
  final List<MealPlanItem> items;
  final double totalBudget;
  final String? notes;

  SavedMealPlan({
    required this.id,
    required this.planName,
    required this.createdAt,
    required this.items,
    required this.totalBudget,
    this.notes,
  });

  factory SavedMealPlan.fromJson(Map<String, dynamic> json) {
    return SavedMealPlan(
      id: json['id'],
      planName: json['plan_name'],
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List)
          .map((item) => MealPlanItem.fromJson(item))
          .toList(),
      totalBudget: (json['total_budget'] as num).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'total_budget': totalBudget,
      'notes': notes,
    };
  }
}

class MealPlanItem {
  final String foodName;
  final String? category;
  final double estimatedCost;
  final String? imageUrl;
  final String? benefits;
  final Map<String, double>? nutrients;

  MealPlanItem({
    required this.foodName,
    this.category,
    required this.estimatedCost,
    this.imageUrl,
    this.benefits,
    this.nutrients,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      foodName: json['food_name'],
      category: json['category'],
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
      imageUrl: json['image_url'],
      benefits: json['benefits'],
      nutrients: json['nutrients'] != null
          ? (json['nutrients'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'category': category,
      'estimated_cost': estimatedCost,
      'image_url': imageUrl,
      'benefits': benefits,
      'nutrients': nutrients,
    };
  }
}

