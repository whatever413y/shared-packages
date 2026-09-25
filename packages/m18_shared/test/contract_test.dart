import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:m18_shared/m18_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real responses from the server (synthetic data; tokens and signed URLs replaced), exported by the
/// server's `export_contract_fixtures` test. Regenerate them whenever the API changes (see README).
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

dynamic decoded(String name) => jsonDecode(fixture(name));

void main() {
  group('models parse the real server responses', () {
    test('room.json', () {
      final room = Room.fromJson(decoded('room.json') as Map<String, dynamic>);
      expect((room.id, room.name, room.rent), (1, 'Room 101', 5000));
    });

    test('tenant.json', () {
      final tenant = Tenant.fromJson(decoded('tenant.json') as Map<String, dynamic>);
      expect((tenant.name, tenant.roomId, tenant.isActive), ('Juan Dela Cruz', 1, true));
      expect(tenant.joinDate, DateTime(2026));
    });

    test('reading.json', () {
      final reading = Reading.fromJson(decoded('reading.json') as Map<String, dynamic>);
      expect((reading.prevReading, reading.currReading, reading.consumption), (100, 150, 50));
    });

    test('bill.json: server-computed total, charges and the nested reading', () {
      final bill = Bill.fromJson(decoded('bill.json') as Map<String, dynamic>);
      expect((bill.roomCharges, bill.electricCharges, bill.totalAmount), (5000, 850, 6050));
      expect(bill.additionalCharges.single.description, 'Water');
      expect(bill.additionalCharges.single.amount, 200);
      expect(bill.consumption, 50);
      expect(bill.paid, isFalse);
      expect(bill.hasReceipt, isFalse);
    });

    test('bills.json and latest_bill.json have the same bill shape', () {
      final list = (decoded('bills.json') as List<dynamic>).map((b) => Bill.fromJson(b as Map<String, dynamic>)).toList();
      final latest = Bill.fromJson(decoded('latest_bill.json') as Map<String, dynamic>);
      expect(list.single.totalAmount, 6050);
      expect(latest.id, list.single.id);
    });
  });

  group('API layer accepts the real server responses', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    ApiClient serving(String name, {String subjectKey = 'admin_id'}) => ApiClient(
      tokens: TokenStore(subjectKey),
      baseUrl: 'http://api.test/api',
      httpClient: MockClient((_) async => http.Response(fixture(name), 200, headers: {'content-type': 'application/json'})),
    );

    test('admin login', () async {
      final session = await AuthApi(serving('admin_login.json')).adminLogin('test-admin', 'pw');
      expect((session.token, session.username), ('<token>', 'test-admin'));
    });

    test('tenant login', () async {
      final session = await AuthApi(serving('tenant_login.json', subjectKey: 'tenant_id')).tenantLogin('JUAN DELA CRUZ');
      expect(session.tenant.name, 'Juan Dela Cruz');
    });

    test('bill list and latest bill', () async {
      expect((await BillApi(serving('bills.json')).listForTenant(1)).single.totalAmount, 6050);
      expect((await BillApi(serving('latest_bill.json')).latestForTenant(1))!.totalAmount, 6050);
    });

    test('signed URL', () async {
      expect(await AuthApi(serving('signed_url.json')).signedPaymentUrl('gcash'), '<signed-url>');
    });
  });
}
