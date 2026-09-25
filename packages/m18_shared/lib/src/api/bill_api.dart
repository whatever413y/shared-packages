import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/bill.dart';
import '../models/requests.dart';
import 'api_client.dart';
import 'api_exception.dart';

class BillApi {
  final ApiClient _client;

  BillApi(this._client);

  Future<List<Bill>> list() async => _bills(await _client.get('/bills'));

  Future<List<Bill>> listForTenant(int tenantId) async => _bills(await _client.get('/bills/$tenantId/bills'));

  /// The tenant's most recent bill, or `null` when they have none (HTTP 404).
  Future<Bill?> latestForTenant(int tenantId) async {
    try {
      return Bill.fromJson(await _client.get('/bills/$tenantId/bill') as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Bill> create(BillRequest request) async =>
      Bill.fromJson(await _client.post('/bills', body: request.toJson(), expected: {201}) as Map<String, dynamic>);

  Future<Bill> update(int id, BillRequest request) async =>
      Bill.fromJson(await _client.put('/bills/$id', body: request.toJson()) as Map<String, dynamic>);

  /// Updates the bill and attaches a receipt image (`receipt_file`, JPEG or PNG by extension).
  Future<Bill> uploadReceipt(int id, BillRequest request, {required List<int> bytes, required String filename}) async {
    final ext = filename.split('.').last.toLowerCase();
    final mediaType = (ext == 'jpg' || ext == 'jpeg') ? MediaType('image', 'jpeg') : MediaType('image', 'png');

    final multipart = http.MultipartRequest('PUT', _client.uri('/bills/$id/upload'))
      ..fields.addAll(request.toMultipartFields())
      ..files.add(http.MultipartFile.fromBytes('receipt_file', bytes, filename: filename, contentType: mediaType));

    return Bill.fromJson(await _client.send(multipart) as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/bills/$id');

  List<Bill> _bills(dynamic data) => (data as List<dynamic>).map((b) => Bill.fromJson(b as Map<String, dynamic>)).toList();
}
