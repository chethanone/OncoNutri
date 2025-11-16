class PatientProfile {
  final int? id;
  final int? userId;
  final int age;
  final double weight;
  final String cancerType;
  final String stage;
  final String allergies;
  final String otherConditions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatientProfile({
    this.id,
    this.userId,
    required this.age,
    required this.weight,
    required this.cancerType,
    required this.stage,
    this.allergies = '',
    this.otherConditions = '',
    this.createdAt,
    this.updatedAt,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'],
      userId: json['user_id'],
      age: json['age'],
      weight: json['weight'].toDouble(),
      cancerType: json['cancer_type'],
      stage: json['stage'],
      allergies: json['allergies'] ?? '',
      otherConditions: json['other_conditions'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'age': age,
      'weight': weight,
      'cancer_type': cancerType,
      'stage': stage,
      'allergies': allergies,
      'other_conditions': otherConditions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
