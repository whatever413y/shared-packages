/// A way to pay (bank or e-wallet) the admin manages, as returned by `GET /api/payment-methods`.
class PaymentMethod {
  final int id;
  final String name;
  final String? accountName;
  final String? accountNumber;

  /// Position in the list (lowest first).
  final int sortOrder;

  /// Whether a QR image is stored (open it with `AuthApi.signedPaymentMethodUrl`).
  final bool hasImage;

  const PaymentMethod({required this.id, required this.name, this.accountName, this.accountNumber, required this.sortOrder, required this.hasImage});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['id'] as int,
    name: json['name'] as String,
    accountName: json['account_name'] as String?,
    accountNumber: json['account_number'] as String?,
    sortOrder: json['sort_order'] as int,
    hasImage: json['has_image'] as bool,
  );

  /// The name for ids and file names, as the server derives it: lowercase, every run of other characters than
  /// `a-z`/`0-9` one `-` ("GCash" → `gcash`, "Union Bank" → `union-bank`).
  String get slug => name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
}
