class DietRecommendation {
  final int? id;
  final int? patientId;
  final List<String> breakfast;
  final List<String> lunch;
  final List<String> dinner;
  final List<String> snacks;
  final String? notes;
  final DateTime? createdAt;

  DietRecommendation({
    this.id,
    this.patientId,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
    this.notes,
    this.createdAt,
  });

  factory DietRecommendation.fromJson(Map<String, dynamic> json) {
    final recommendation = json['recommendation'] ?? json;
    
    return DietRecommendation(
      id: json['id'],
      patientId: json['patient_id'],
      breakfast: List<String>.from(recommendation['breakfast'] ?? []),
      lunch: List<String>.from(recommendation['lunch'] ?? []),
      dinner: List<String>.from(recommendation['dinner'] ?? []),
      snacks: List<String>.from(recommendation['snacks'] ?? []),
      notes: recommendation['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'recommendation': {
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'snacks': snacks,
        'notes': notes,
      },
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

