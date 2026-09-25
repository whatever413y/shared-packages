import 'dart:convert';

import 'package:intl/intl.dart';

import 'additional_charge.dart';

/// Request bodies for creating/updating records. Keys and formats match what the server expects.

class RoomRequest {
  final String name;
  final int rent;

  const RoomRequest({required this.name, required this.rent});

  Map<String, dynamic> toJson() => {'name': name, 'rent': rent};
}

class TenantRequest {
  /// The server parses `join_date` as a naive date-time, so no timezone suffix is sent.
  static final DateFormat _joinDateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  final String name;
  final int roomId;
  final DateTime joinDate;

  /// Only sent on update; creation lets the server default it to active.
  final bool? isActive;

  const TenantRequest({required this.name, required this.roomId, required this.joinDate, this.isActive});

  Map<String, dynamic> toJson() => {
    'name': name,
    'room_id': roomId,
    'join_date': _joinDateFormat.format(joinDate),
    if (isActive != null) 'is_active': isActive,
  };
}

class ReadingRequest {
  final int roomId;
  final int tenantId;
  final int prevReading;
  final int currReading;

  const ReadingRequest({required this.roomId, required this.tenantId, required this.prevReading, required this.currReading});

  Map<String, dynamic> toJson() => {'room_id': roomId, 'tenant_id': tenantId, 'prev_reading': prevReading, 'curr_reading': currReading};
}

class BillRequest {
  final int tenantId;
  final int readingId;
  final int roomCharges;
  final int electricCharges;
  final List<AdditionalCharge> additionalCharges;
  final String? receiptUrl;

  const BillRequest({
    required this.tenantId,
    required this.readingId,
    required this.roomCharges,
    required this.electricCharges,
    this.additionalCharges = const [],
    this.receiptUrl,
  });

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'reading_id': readingId,
    'room_charges': roomCharges,
    'electric_charges': electricCharges,
    'additional_charges': additionalCharges.map((c) => c.toJson()).toList(),
    'receipt_url': receiptUrl,
  };

  /// Form fields for the multipart receipt upload (`PUT /bills/{id}/upload`).
  Map<String, String> toMultipartFields() => {
    'tenant_id': '$tenantId',
    'reading_id': '$readingId',
    'room_charges': '$roomCharges',
    'electric_charges': '$electricCharges',
    'additional_charges': jsonEncode(additionalCharges.map((c) => c.toJson()).toList()),
    'receipt_url': receiptUrl ?? '',
  };
}
