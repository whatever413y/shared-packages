import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/payment_image.dart';
import 'api_client.dart';

/// Payment QR images (admin only); everyone logged in opens them via `AuthApi.signedPaymentUrl`.
class PaymentApi {
  final ApiClient _client;

  PaymentApi(this._client);

  /// Every payment method with whether its image is stored.
  Future<List<PaymentImage>> list() async =>
      (await _client.get('/payments') as List<dynamic>).map((p) => PaymentImage.fromJson(p as Map<String, dynamic>)).toList();

  /// Replaces the QR image of the method [name] with [png] (the server accepts PNG only).
  Future<PaymentImage> upload(String name, List<int> png) async {
    final multipart = http.MultipartRequest('PUT', _client.uri('/payments/${Uri.encodeComponent(name)}'))
      ..files.add(http.MultipartFile.fromBytes('file', png, filename: '$name.png', contentType: MediaType('image', 'png')));
    return PaymentImage.fromJson(await _client.send(multipart) as Map<String, dynamic>);
  }
}
