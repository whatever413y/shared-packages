import '../models/reading.dart';
import '../models/requests.dart';
import 'api_client.dart';

class ReadingApi {
  final ApiClient _client;

  ReadingApi(this._client);

  Future<List<Reading>> list() async =>
      (await _client.get('/electricity-readings') as List<dynamic>).map((r) => Reading.fromJson(r as Map<String, dynamic>)).toList();

  Future<Reading> create(ReadingRequest request) async =>
      Reading.fromJson(await _client.post('/electricity-readings', body: request.toJson(), expected: {201}) as Map<String, dynamic>);

  Future<Reading> update(int id, ReadingRequest request) async =>
      Reading.fromJson(await _client.put('/electricity-readings/$id', body: request.toJson()) as Map<String, dynamic>);

  Future<void> delete(int id) => _client.delete('/electricity-readings/$id');
}
