/// One body-weight reading logged over time — distinct from the single
/// "current" weight/weightUnit on the user's profile, which this doesn't
/// replace. Powers the Progress screen's body-stats trend.
class WeightLog {
  const WeightLog({
    required this.id,
    required this.weight,
    required this.weightUnit,
    required this.loggedAt,
  });

  final int id;
  final double weight;
  final String weightUnit;
  final DateTime loggedAt;

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'] as int,
      weight: (json['weight'] as num).toDouble(),
      weightUnit: json['weight_unit']?.toString() ?? 'kg',
      loggedAt: DateTime.tryParse(json['logged_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
