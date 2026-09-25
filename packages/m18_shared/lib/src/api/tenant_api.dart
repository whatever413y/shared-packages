import '../models/requests.dart';
import '../models/tenant.dart';
import 'api_client.dart';

class TenantApi {
  final ApiClient _client;

  TenantApi(this._client);

  Future<List<Tenant>> list() async =>
      (await _client.get('/tenants') as List<dynamic>).map((t) => Tenant.fromJson(t as Map<String, dynamic>)).toList();

  Future<Tenant> getById(int id) async => Tenant.fromJson(await _client.get('/tenants/$id') as Map<String, dynamic>);

  Future<Tenant> create(TenantRequest request) async =>
      Tenant.fromJson(await _client.post('/tenants', body: request.toJson(), expected: {201}) as Map<String, dynamic>);

  Future<Tenant> update(int id, TenantRequest request) async =>
      Tenant.fromJson(await _client.put('/tenants/$id', body: request.toJson()) as Map<String, dynamic>);

  Future<void> delete(int id) => _client.delete('/tenants/$id');
}
