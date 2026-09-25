import '../models/requests.dart';
import '../models/room.dart';
import 'api_client.dart';

class RoomApi {
  final ApiClient _client;

  RoomApi(this._client);

  Future<List<Room>> list() async => (await _client.get('/rooms') as List<dynamic>).map((r) => Room.fromJson(r as Map<String, dynamic>)).toList();

  Future<Room> create(RoomRequest request) async =>
      Room.fromJson(await _client.post('/rooms', body: request.toJson(), expected: {201}) as Map<String, dynamic>);

  Future<Room> update(int id, RoomRequest request) async =>
      Room.fromJson(await _client.put('/rooms/$id', body: request.toJson()) as Map<String, dynamic>);

  Future<void> delete(int id) => _client.delete('/rooms/$id');
}
