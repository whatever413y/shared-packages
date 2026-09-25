import 'package:flutter_test/flutter_test.dart';
import 'package:m18_shared/m18_shared.dart';

Map<String, dynamic> billJson({Map<String, dynamic>? reading, Object? receiptUrl}) => {
  'bill': {
    'id': 7,
    'reading_id': 3,
    'tenant_id': 2,
    'room_charges': 5000,
    'electric_charges': 850,
    'total_amount': 6050,
    'receipt_url': receiptUrl,
    'paid': false,
    'created_at': '2026-09-25T10:00:00.123456',
    'updated_at': '2026-09-25T10:00:00.123456',
  },
  'additional_charges': [
    {'id': 1, 'bill_id': 7, 'amount': 200, 'description': 'Water', 'created_at': '2026-09-25T10:00:00', 'updated_at': '2026-09-25T10:00:00'},
  ],
  'reading': reading,
};

const readingJson = {
  'id': 3,
  'tenant_id': 2,
  'room_id': 1,
  'prev_reading': 100,
  'curr_reading': 150,
  'consumption': 50,
  'created_at': '2026-09-24T09:00:00',
  'updated_at': '2026-09-24T09:00:00',
};

void main() {
  group('Bill.fromJson', () {
    test('parses the bill, its charges and the nested reading', () {
      final bill = Bill.fromJson(billJson(reading: readingJson));

      expect(bill.id, 7);
      expect(bill.tenantId, 2);
      expect(bill.readingId, 3);
      expect(bill.roomCharges, 5000);
      expect(bill.electricCharges, 850);
      expect(bill.totalAmount, 6050);
      expect(bill.paid, isFalse);
      expect(bill.createdAt, DateTime.parse('2026-09-25T10:00:00.123456'));
      expect(bill.additionalCharges.single.amount, 200);
      expect(bill.additionalCharges.single.description, 'Water');
      expect(bill.reading!.roomId, 1);
      expect((bill.prevReading, bill.currReading, bill.consumption), (100, 150, 50));
    });

    test('reading getters fall back to 0 when the server sends no reading', () {
      final bill = Bill.fromJson(billJson());
      expect(bill.reading, isNull);
      expect((bill.prevReading, bill.currReading, bill.consumption), (0, 0, 0));
    });

    test('hasReceipt is false for a null or empty receipt URL', () {
      expect(Bill.fromJson(billJson()).hasReceipt, isFalse);
      expect(Bill.fromJson(billJson(receiptUrl: '')).hasReceipt, isFalse);
      expect(Bill.fromJson(billJson(receiptUrl: '1727000000-r3')).hasReceipt, isTrue);
    });

    test('treats missing additional_charges as none', () {
      final json = billJson()..remove('additional_charges');
      expect(Bill.fromJson(json).additionalCharges, isEmpty);
    });
  });

  test('Reading.fromJson', () {
    final reading = Reading.fromJson(readingJson);
    expect((reading.id, reading.tenantId, reading.roomId, reading.consumption), (3, 2, 1, 50));
    expect(reading.createdAt, DateTime(2026, 9, 24, 9));
  });

  test('Tenant.fromJson', () {
    final tenant = Tenant.fromJson({
      'id': 2,
      'room_id': 1,
      'name': 'JUAN DELA CRUZ',
      'is_active': true,
      'join_date': '2026-01-01T00:00:00',
      'created_at': '2026-01-01T00:00:00',
      'updated_at': '2026-01-01T00:00:00',
    });
    expect((tenant.id, tenant.roomId, tenant.name, tenant.isActive), (2, 1, 'JUAN DELA CRUZ', true));
    expect(tenant.joinDate, DateTime(2026));
  });

  test('Room.fromJson', () {
    final room = Room.fromJson({'id': 1, 'name': 'Room 101', 'rent': 5000, 'created_at': '2026-01-01T00:00:00', 'updated_at': '2026-01-01T00:00:00'});
    expect((room.id, room.name, room.rent), (1, 'Room 101', 5000));
  });

  group('requests', () {
    test('TenantRequest sends a naive join_date and omits is_active on create', () {
      final json = TenantRequest(name: 'ANA', roomId: 1, joinDate: DateTime(2026, 1, 5, 8, 30)).toJson();
      expect(json, {'name': 'ANA', 'room_id': 1, 'join_date': '2026-01-05T08:30:00'});
    });

    test('TenantRequest includes is_active on update', () {
      final json = TenantRequest(name: 'ANA', roomId: 1, joinDate: DateTime(2026), isActive: false).toJson();
      expect(json['is_active'], isFalse);
    });

    test('RoomRequest and ReadingRequest use the server keys', () {
      expect(RoomRequest(name: 'Room 101', rent: 5000).toJson(), {'name': 'Room 101', 'rent': 5000});
      expect(ReadingRequest(roomId: 1, tenantId: 2, prevReading: 100, currReading: 150).toJson(), {
        'room_id': 1,
        'tenant_id': 2,
        'prev_reading': 100,
        'curr_reading': 150,
      });
    });

    test('BillRequest JSON and multipart fields', () {
      final request = BillRequest(
        tenantId: 2,
        readingId: 3,
        roomCharges: 5000,
        electricCharges: 850,
        additionalCharges: const [AdditionalCharge(amount: 200, description: 'Water')],
      );

      expect(request.toJson(), {
        'tenant_id': 2,
        'reading_id': 3,
        'room_charges': 5000,
        'electric_charges': 850,
        'additional_charges': [
          {'amount': 200, 'description': 'Water'},
        ],
        'receipt_url': null,
      });
      expect(request.toMultipartFields(), {
        'tenant_id': '2',
        'reading_id': '3',
        'room_charges': '5000',
        'electric_charges': '850',
        'additional_charges': '[{"amount":200,"description":"Water"}]',
        'receipt_url': '',
      });
    });
  });
}
