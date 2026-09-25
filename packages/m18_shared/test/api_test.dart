import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:m18_shared/m18_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

const base = 'http://api.test/api';

const tenantJson = {'id': 2, 'room_id': 1, 'name': 'ANA', 'is_active': true, 'join_date': '2026-01-01T00:00:00'};

final billJson = {
  'bill': {
    'id': 7,
    'reading_id': 3,
    'tenant_id': 2,
    'room_charges': 5000,
    'electric_charges': 850,
    'total_amount': 6050,
    'receipt_url': null,
    'paid': false,
    'created_at': '2026-09-25T10:00:00',
  },
  'additional_charges': <Object>[],
  'reading': null,
};

http.Response json(Object? body, int status) => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  late List<http.Request> sent;

  /// Client whose requests are recorded in [sent] and answered by [handler].
  ApiClient client(Future<http.Response> Function(http.Request) handler, {String subjectKey = 'admin_id'}) => ApiClient(
    tokens: TokenStore(subjectKey),
    baseUrl: base,
    httpClient: MockClient((request) {
      sent.add(request);
      return handler(request);
    }),
  );

  setUp(() {
    sent = [];
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiClient', () {
    test('sends JSON content type, adding the bearer token only when logged in', () async {
      final api = RoomApi(client((_) async => json([], 200)));

      await api.list();
      expect(sent.last.headers['Content-Type'], 'application/json');
      expect(sent.last.headers.containsKey('Authorization'), isFalse);

      SharedPreferences.setMockInitialValues({'auth_token': 'abc'});
      await api.list();
      expect(sent.last.headers['Authorization'], 'Bearer abc');
      expect(sent.last.url.toString(), '$base/rooms');
    });

    test('an unexpected status throws ApiException carrying the server error message', () async {
      final api = RoomApi(client((_) async => json({'error': 'boom'}, 500)));

      await expectLater(
        api.list(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500).having((e) => e.message, 'message', 'boom')),
      );
    });

    test('ApiConfig.baseUrl fails loudly when API_URL was not defined', () {
      expect(() => ApiConfig.baseUrl, throwsStateError);
    });
  });

  group('AuthApi', () {
    test('admin login saves the token and username', () async {
      final auth = AuthApi(client((_) async => json({'token': 't1', 'role': 'admin', 'username': 'admin'}, 200)));

      final session = await auth.adminLogin('admin', 'pw');

      expect((session.token, session.username), ('t1', 'admin'));
      expect(jsonDecode(sent.single.body), {'username': 'admin', 'password': 'pw'});
      expect(await auth.tokens.token(), 't1');
      expect(await auth.tokens.subject(), 'admin');
    });

    test('admin login maps 401 to InvalidCredentialsException', () async {
      final auth = AuthApi(client((_) async => json({'error': 'Invalid credentials'}, 401)));
      await expectLater(auth.adminLogin('admin', 'wrong'), throwsA(isA<InvalidCredentialsException>()));
    });

    test('tenant login saves the token and tenant id', () async {
      final auth = AuthApi(client((_) async => json({'token': 't2', 'tenant': tenantJson}, 200), subjectKey: 'tenant_id'));

      final session = await auth.tenantLogin('ANA');

      expect(session.tenant.name, 'ANA');
      expect(jsonDecode(sent.single.body), {'name': 'ANA'});
      expect(await auth.tokens.subject(), '2');
    });

    test('tenant login maps 404 to TenantNotFoundException', () async {
      final auth = AuthApi(client((_) async => json({'error': 'Tenant not found'}, 404), subjectKey: 'tenant_id'));
      await expectLater(auth.tenantLogin('NOBODY'), throwsA(isA<TenantNotFoundException>()));
    });

    test('validateToken: false without a token (no request), true on 200, false on 401, throws on 500', () async {
      var status = 200;
      final auth = AuthApi(client((_) async => json({}, status)));

      expect(await auth.validateToken(), isFalse);
      expect(sent, isEmpty);

      SharedPreferences.setMockInitialValues({'auth_token': 'abc'});
      expect(await auth.validateToken(), isTrue);
      expect(sent.last.url.path, '/api/auth/validate-token');

      status = 401;
      expect(await auth.validateToken(), isFalse);

      status = 500;
      await expectLater(auth.validateToken(), throwsA(isA<ApiException>()));
    });

    test('logout clears the token and subject', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'abc', 'admin_id': 'admin'});
      final auth = AuthApi(client((_) async => json({}, 200)));

      await auth.logout();

      expect(await auth.tokens.token(), isNull);
      expect(await auth.tokens.subject(), isNull);
    });

    test('signed URLs encode path segments and return the url', () async {
      final auth = AuthApi(client((_) async => json({'url': 'https://r2.test/signed'}, 200)));

      expect(await auth.signedReceiptUrl('JUAN DELA CRUZ', '1727000000-r3'), 'https://r2.test/signed');
      expect(sent.last.url.toString(), '$base/signed-urls/receipts/JUAN%20DELA%20CRUZ/1727000000-r3');

      await auth.signedPaymentUrl('gcash');
      expect(sent.last.url.toString(), '$base/signed-urls/payments/gcash');
    });
  });

  group('BillApi', () {
    test('lists bills for a tenant and returns the latest', () async {
      final bills = BillApi(client((request) async => json(request.url.path.endsWith('/bills') ? [billJson] : billJson, 200)));

      expect((await bills.listForTenant(2)).single.totalAmount, 6050);
      expect(sent.last.url.path, '/api/bills/2/bills');
      expect((await bills.latestForTenant(2))!.id, 7);
      expect(sent.last.url.path, '/api/bills/2/bill');
    });

    test('latestForTenant returns null when the tenant has no bill (404)', () async {
      final bills = BillApi(client((_) async => json({'error': 'Not found'}, 404)));
      expect(await bills.latestForTenant(2), isNull);
    });

    test('create posts the request and expects 201', () async {
      var status = 201;
      final bills = BillApi(client((_) async => json(billJson, status)));
      const request = BillRequest(tenantId: 2, readingId: 3, roomCharges: 5000, electricCharges: 850);

      expect((await bills.create(request)).id, 7);
      expect(sent.last.method, 'POST');
      expect(jsonDecode(sent.last.body)['room_charges'], 5000);

      status = 200;
      await expectLater(bills.create(request), throwsA(isA<ApiException>()));
    });

    test('uploadReceipt sends a multipart PUT with the form fields and a JPEG file part', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'abc'});
      final bills = BillApi(client((_) async => json(billJson, 200)));
      const request = BillRequest(tenantId: 2, readingId: 3, roomCharges: 5000, electricCharges: 850);

      await bills.uploadReceipt(7, request, bytes: [1, 2, 3], filename: 'receipt.JPG');

      final upload = sent.single;
      expect(upload.method, 'PUT');
      expect(upload.url.path, '/api/bills/7/upload');
      expect(upload.headers['Authorization'], 'Bearer abc');
      expect(upload.headers['content-type'], startsWith('multipart/form-data'));
      final body = latin1.decode(upload.bodyBytes);
      expect(body, contains('name="room_charges"'));
      expect(body, contains('name="receipt_file"; filename="receipt.JPG"'));
      expect(body, contains('content-type: image/jpeg'));
    });

    test('delete expects 204', () async {
      final bills = BillApi(client((_) async => http.Response('', 204)));
      await bills.delete(7);
      expect((sent.single.method, sent.single.url.path), ('DELETE', '/api/bills/7'));
    });
  });

  test('Room, tenant and reading APIs use the expected paths and bodies', () async {
    final api = client((request) async {
      final path = request.url.path;
      if (path.startsWith('/api/rooms')) return json({'id': 1, 'name': 'Room 101', 'rent': 5000}, request.method == 'POST' ? 201 : 200);
      if (path.startsWith('/api/tenants')) return json(tenantJson, request.method == 'POST' ? 201 : 200);
      return json({
        'id': 3,
        'tenant_id': 2,
        'room_id': 1,
        'prev_reading': 100,
        'curr_reading': 150,
        'consumption': 50,
        'created_at': '2026-09-24T09:00:00',
      }, request.method == 'POST' ? 201 : 200);
    });

    await RoomApi(api).update(1, const RoomRequest(name: 'Room 101', rent: 5000));
    expect((sent.last.method, sent.last.url.path), ('PUT', '/api/rooms/1'));

    await TenantApi(api).create(TenantRequest(name: 'ANA', roomId: 1, joinDate: DateTime(2026)));
    expect((sent.last.method, sent.last.url.path), ('POST', '/api/tenants'));
    expect(jsonDecode(sent.last.body), {'name': 'ANA', 'room_id': 1, 'join_date': '2026-01-01T00:00:00'});

    expect((await TenantApi(api).getById(2)).name, 'ANA');
    expect(sent.last.url.path, '/api/tenants/2');

    await ReadingApi(api).create(const ReadingRequest(roomId: 1, tenantId: 2, prevReading: 100, currReading: 150));
    expect((sent.last.method, sent.last.url.path), ('POST', '/api/electricity-readings'));
  });
}
