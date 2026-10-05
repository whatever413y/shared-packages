import 'additional_charge.dart';
import 'reading.dart';
import 'server_time.dart';

/// Where a bill stands: [unpaid], [forVerification] (the tenant's payment image is there, the owner hasn't
/// attached a receipt yet) or [paid] (a receipt is attached; the payment image is optional).
enum BillStatus {
  unpaid('Unpaid'),
  forVerification('For verification'),
  paid('Paid');

  final String label;

  const BillStatus(this.label);
}

/// A bill as returned by the API: `{"bill": {...}, "additional_charges": [...], "reading": {...}}`.
class Bill {
  final int id;
  final int tenantId;
  final int readingId;
  final int roomCharges;
  final int electricCharges;
  final int totalAmount;
  final bool paid;
  final String? receiptUrl;

  /// The tenant's proof of payment (file name under `tenant-payments/<tenant name>/`).
  final String? paymentUrl;
  final DateTime createdAt;
  final List<AdditionalCharge> additionalCharges;
  final Reading? reading;

  const Bill({
    required this.id,
    required this.tenantId,
    required this.readingId,
    required this.roomCharges,
    required this.electricCharges,
    required this.totalAmount,
    required this.paid,
    required this.createdAt,
    this.receiptUrl,
    this.paymentUrl,
    this.additionalCharges = const [],
    this.reading,
  });

  /// Meter values of the bill's reading; 0 when the server sent no reading.
  int get prevReading => reading?.prevReading ?? 0;
  int get currReading => reading?.currReading ?? 0;
  int get consumption => reading?.consumption ?? 0;

  bool get hasReceipt => receiptUrl?.isNotEmpty ?? false;

  bool get hasPayment => paymentUrl?.isNotEmpty ?? false;

  BillStatus get status => hasReceipt
      ? BillStatus.paid
      : hasPayment
      ? BillStatus.forVerification
      : BillStatus.unpaid;

  factory Bill.fromJson(Map<String, dynamic> json) {
    final bill = json['bill'] as Map<String, dynamic>;
    final charges = json['additional_charges'] as List<dynamic>? ?? const [];
    final reading = json['reading'] as Map<String, dynamic>?;

    return Bill(
      id: bill['id'] as int,
      tenantId: bill['tenant_id'] as int,
      readingId: bill['reading_id'] as int,
      roomCharges: bill['room_charges'] as int,
      electricCharges: bill['electric_charges'] as int,
      totalAmount: bill['total_amount'] as int,
      paid: bill['paid'] as bool,
      receiptUrl: bill['receipt_url'] as String?,
      paymentUrl: bill['payment_url'] as String?,
      createdAt: parseServerTimestamp(bill['created_at'] as String),
      additionalCharges: charges.map((c) => AdditionalCharge.fromJson(c as Map<String, dynamic>)).toList(),
      reading: reading == null ? null : Reading.fromJson(reading),
    );
  }
}
