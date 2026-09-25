/// A tenant as returned by the API (the server always sends the full record).
class Tenant {
  final int id;
  final int roomId;
  final String name;
  final DateTime joinDate;
  final bool isActive;

  const Tenant({required this.id, required this.roomId, required this.name, required this.joinDate, required this.isActive});

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
    id: json['id'] as int,
    roomId: json['room_id'] as int,
    name: json['name'] as String,
    joinDate: DateTime.parse(json['join_date'] as String),
    isActive: json['is_active'] as bool,
  );
}
