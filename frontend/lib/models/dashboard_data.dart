class DashboardData {
  final DashboardOverview overview;
  final List<FoodRecommendationSimple> recommendations;
  final List<HealthTip> tips;
  final ProfileSummary profile;

  DashboardData({
    required this.overview,
    required this.recommendations,
    required this.tips,
    required this.profile,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      overview: DashboardOverview.fromJson(json['overview']),
      recommendations: (json['recommendations'] as List?)
          ?.map((rec) => FoodRecommendationSimple.fromJson(rec))
          .toList() ?? [],
      tips: (json['tips'] as List)
          .map((tip) => HealthTip.fromJson(tip))
          .toList(),
      profile: ProfileSummary.fromJson(json['profile']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overview': {
        'dietPlanStatus': overview.dietPlanStatus,
        'progressPercentage': overview.progressPercentage,
        'hasDietPlan': overview.hasDietPlan,
        'totalProgressEntries': overview.totalProgressEntries,
        'lastEntryDate': overview.lastEntryDate,
        'totalRecommendedFoods': overview.totalRecommendedFoods,
        'lastRecommendationDate': overview.lastRecommendationDate,
      },
      'recommendations': recommendations.map((rec) => {
        'name': rec.name,
        'score': rec.score,
        'image_url': rec.imageUrl,
        'benefits': rec.benefits,
        'food_type': rec.foodType,
      }).toList(),
      'tips': tips.map((tip) => {
        'icon': tip.icon,
        'title': tip.title,
        'description': tip.description,
      }).toList(),
      'profile': {
        'cancerType': profile.cancerType,
        'stage': profile.stage,
        'age': profile.age,
      },
    };
  }
}

class DashboardOverview {
  final String dietPlanStatus;
  final int progressPercentage;
  final bool hasDietPlan;
  final int totalProgressEntries;
  final String? lastEntryDate;
  final int totalRecommendedFoods;
  final String? lastRecommendationDate;

  DashboardOverview({
    required this.dietPlanStatus,
    required this.progressPercentage,
    required this.hasDietPlan,
    required this.totalProgressEntries,
    this.lastEntryDate,
    required this.totalRecommendedFoods,
    this.lastRecommendationDate,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      dietPlanStatus: json['dietPlanStatus'],
      progressPercentage: json['progressPercentage'],
      hasDietPlan: json['hasDietPlan'],
      totalProgressEntries: json['totalProgressEntries'],
      lastEntryDate: json['lastEntryDate'],
      totalRecommendedFoods: json['totalRecommendedFoods'] ?? 0,
      lastRecommendationDate: json['lastRecommendationDate'],
    );
  }
}

class HealthTip {
  final String icon;
  final String title;
  final String description;

  HealthTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      icon: json['icon'],
      title: json['title'],
      description: json['description'],
    );
  }
}

class ProfileSummary {
  final String cancerType;
  final String? stage;
  final int? age;

  ProfileSummary({
    required this.cancerType,
    this.stage,
    this.age,
  });

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      cancerType: json['cancerType'],
      stage: json['stage'],
      age: json['age'],
    );
  }
}

class FoodRecommendationSimple {
  final String name;
  final double score;
  final String? imageUrl;
  final String? benefits;
  final String? foodType;

  FoodRecommendationSimple({
    required this.name,
    required this.score,
    this.imageUrl,
    this.benefits,
    this.foodType,
  });

  factory FoodRecommendationSimple.fromJson(Map<String, dynamic> json) {
    return FoodRecommendationSimple(
      name: json['name'],
      score: (json['score'] as num).toDouble(),
      imageUrl: json['image_url'],
      benefits: json['benefits'],
      foodType: json['food_type'],
    );
  }
}

