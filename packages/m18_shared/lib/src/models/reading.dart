/// An electricity meter reading for one tenant in one room.
class Reading {
  final int id;
  final int tenantId;
  final int roomId;
  final int prevReading;
  final int currReading;
  final int consumption;
  final DateTime createdAt;

  const Reading({
    required this.id,
    required this.tenantId,
    required this.roomId,
    required this.prevReading,
    required this.currReading,
    required this.consumption,
    required this.createdAt,
  });

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
    id: json['id'] as int,
    tenantId: json['tenant_id'] as int,
    roomId: json['room_id'] as int,
    prevReading: json['prev_reading'] as int,
    currReading: json['curr_reading'] as int,
    consumption: json['consumption'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
