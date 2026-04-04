class HealthEntry {
  final String id;
  final DateTime date;
  final double weight;
  final double bodyMass;
  final double height;
  final double cholesterol;
  final int steps;

  HealthEntry({
    String? id,
    required this.date,
    this.weight = 0,
    this.bodyMass = 0,
    this.height = 0,
    this.cholesterol = 0,
    this.steps = 0,
  }) : id = id ?? date.toIso8601String().split('T')[0];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'bodyMass': bodyMass,
      'height': height,
      'cholesterol': cholesterol,
      'steps': steps,
    };
  }

  factory HealthEntry.fromMap(Map<String, dynamic> map) {
    return HealthEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      weight: map['weight']?.toDouble() ?? 0.0,
      bodyMass: map['bodyMass']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
      cholesterol: map['cholesterol']?.toDouble() ?? 0.0,
      steps: map['steps']?.toInt() ?? 0,
    );
  }
}
