/// A rentable room.
class Room {
  final int id;
  final String name;
  final int rent;

  const Room({required this.id, required this.name, required this.rent});

  factory Room.fromJson(Map<String, dynamic> json) => Room(id: json['id'] as int, name: json['name'] as String, rent: (json['rent'] as num).toInt());
}
