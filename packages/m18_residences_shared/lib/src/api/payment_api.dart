import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/payment_method.dart';
import '../models/requests.dart';
import 'api_client.dart';

/// Payment methods: listed for everyone logged in, changed by the admin only. QR images open through
/// `AuthApi.signedPaymentMethodUrl`.
class PaymentApi {
  final ApiClient _client;

  PaymentApi(this._client);

  /// Every payment method, in list order.
  Future<List<PaymentMethod>> list() async =>
      (await _client.get('/payment-methods') as List<dynamic>).map((p) => PaymentMethod.fromJson(p as Map<String, dynamic>)).toList();

  Future<PaymentMethod> create(PaymentMethodRequest request) async =>
      PaymentMethod.fromJson(await _client.post('/payment-methods', body: request.toJson(), expected: {201}) as Map<String, dynamic>);

  Future<PaymentMethod> update(int id, PaymentMethodRequest request) async =>
      PaymentMethod.fromJson(await _client.put('/payment-methods/$id', body: request.toJson()) as Map<String, dynamic>);

  /// Deletes the method (its QR image is archived).
  Future<void> delete(int id) => _client.delete('/payment-methods/$id');

  /// Replaces the method's QR image with [png] (the server accepts PNG only, at most 2 MiB).
  Future<PaymentMethod> uploadImage(int id, List<int> png) async {
    final multipart = http.MultipartRequest('PUT', _client.uri('/payment-methods/$id/image'))
      ..files.add(http.MultipartFile.fromBytes('file', png, filename: 'qr.png', contentType: MediaType('image', 'png')));
    return PaymentMethod.fromJson(await _client.send(multipart) as Map<String, dynamic>);
  }

  /// Removes the method's QR image (archived on the server).
  Future<PaymentMethod> deleteImage(int id) async =>
      PaymentMethod.fromJson(await _client.delete('/payment-methods/$id/image', expected: {200}) as Map<String, dynamic>);
}
