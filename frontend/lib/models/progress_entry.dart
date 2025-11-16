class ProgressEntry {
  final int? id;
  final int? patientId;
  final DateTime date;
  final int adherenceScore;
  final String notes;

  ProgressEntry({
    this.id,
    this.patientId,
    required this.date,
    required this.adherenceScore,
    this.notes = '',
  });

  factory ProgressEntry.fromJson(Map<String, dynamic> json) {
    return ProgressEntry(
      id: json['id'],
      patientId: json['patient_id'],
      date: DateTime.parse(json['date']),
      adherenceScore: json['adherence_score'],
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'date': date.toIso8601String().split('T')[0],
      'adherence_score': adherenceScore,
      'notes': notes,
    };
  }
}
