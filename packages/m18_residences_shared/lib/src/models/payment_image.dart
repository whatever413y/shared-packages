/// A payment method's QR image (`payments/<name>.png`), as listed by `GET /api/payments`.
class PaymentImage {
  /// The method's id, e.g. `gcash`.
  final String name;

  /// The storage key, e.g. `payments/gcash.png`.
  final String key;

  /// Whether an image is stored for this method.
  final bool exists;

  const PaymentImage({required this.name, required this.key, required this.exists});

  factory PaymentImage.fromJson(Map<String, dynamic> json) =>
      PaymentImage(name: json['name'] as String, key: json['key'] as String, exists: json['exists'] as bool);
}
