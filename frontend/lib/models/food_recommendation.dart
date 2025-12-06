class FoodRecommendation {
  final int? id;  // Database ID from saved_diet_items
  final int fdcId;
  final String name;
  final double score;
  final double? contentScore;
  final double? collabScore;
  final double? deepScore;
  final String dataType;
  final String? category;
  final Map<String, double> keyNutrients;
  final String? imageUrl;  // Food image URL
  final String? cuisine;  // Cuisine type (Indian, Chinese, etc.)
  final String? texture;  // Food texture (Soft, Liquid, etc.)
  final String? preparation;  // Cooking method
  final String? benefits;  // Health benefits
  final String? foodType;  // Pure Veg, Non-Veg, Vegan, etc.

  FoodRecommendation({
    this.id,
    required this.fdcId,
    required this.name,
    required this.score,
    this.contentScore,
    this.collabScore,
    this.deepScore,
    required this.dataType,
    this.category,
    required this.keyNutrients,
    this.imageUrl,
    this.cuisine,
    this.texture,
    this.preparation,
    this.benefits,
    this.foodType,
  });

  factory FoodRecommendation.fromJson(Map<String, dynamic> json) {
    return FoodRecommendation(
      id: json['id'],
      fdcId: json['fdc_id'],
      name: json['name'],
      score: (json['score'] as num).toDouble(),
      contentScore: json['content_score'] != null ? (json['content_score'] as num).toDouble() : null,
      collabScore: json['collab_score'] != null ? (json['collab_score'] as num).toDouble() : null,
      deepScore: json['deep_score'] != null ? (json['deep_score'] as num).toDouble() : null,
      dataType: json['data_type'],
      category: json['category'],
      keyNutrients: (json['key_nutrients'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      imageUrl: json['image_url'],
      cuisine: json['cuisine'],
      texture: json['texture'],
      preparation: json['preparation'],
      benefits: json['benefits'],
      foodType: json['food_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fdc_id': fdcId,
      'name': name,
      'score': score,
      'content_score': contentScore,
      'collab_score': collabScore,
      'deep_score': deepScore,
      'data_type': dataType,
      'category': category,
      'key_nutrients': keyNutrients,
      'image_url': imageUrl,
      'cuisine': cuisine,
      'texture': texture,
      'preparation': preparation,
      'benefits': benefits,
      'food_type': foodType,
    };
  }
}

class FoodNutrition {
  final int fdcId;
  final String name;
  final String dataType;
  final Map<String, double> nutrients;
  final String servingSize;

  FoodNutrition({
    required this.fdcId,
    required this.name,
    required this.dataType,
    required this.nutrients,
    required this.servingSize,
  });

  factory FoodNutrition.fromJson(Map<String, dynamic> json) {
    return FoodNutrition(
      fdcId: json['fdc_id'],
      name: json['name'],
      dataType: json['data_type'],
      nutrients: (json['nutrients'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      servingSize: json['serving_size'] ?? '100g',
    );
  }
}

class FoodSearchResult {
  final int fdcId;
  final String description;
  final String dataType;
  final String? category;

  FoodSearchResult({
    required this.fdcId,
    required this.description,
    required this.dataType,
    this.category,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      fdcId: json['fdc_id'],
      description: json['description'],
      dataType: json['data_type'],
      category: json['category'],
    );
  }
}

