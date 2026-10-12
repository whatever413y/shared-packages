import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:m18_residences_shared/m18_residences_shared.dart';

void main() {
  String server(String message) => '{"error": "$message"}';

  test('readableError turns errors into one plain sentence', () {
    expect(readableError(const SessionExpiredException(401, '')), 'Your session has ended. Please log in again.');
    expect(readableError(ApiException(401, server('Authentication required'))), 'Your session has ended. Please log in again.');
    expect(readableError(ApiException(403, server('Admin access required'))), "You don't have access to this.");
    expect(readableError(const ApiException(413, '')), 'The file is too large.');
    expect(readableError(const ApiException(429, '')), 'Too many attempts. Please wait a minute and try again.');
    expect(readableError(ApiException(500, server('db exploded'))), 'Something went wrong on our side. Please try again in a moment.');
    expect(readableError(const ApiException(502, '<html>')), 'Something went wrong on our side. Please try again in a moment.');
    expect(
      readableError(ApiException(409, server('This bill changed meanwhile. Reload and try again.'))),
      'This bill changed meanwhile. Reload and try again.',
    );
    expect(readableError(ApiException(404, server('Bill not found'))), 'Bill not found.');
    expect(readableError(const ApiException(400, '')), 'Something went wrong. Please try again.');
    expect(readableError(http.ClientException('XMLHttpRequest error.')), "Can't reach the server. Check your internet connection and try again.");
    expect(readableError(TimeoutException('slow')), 'The server is taking too long to answer. Please try again.');
    expect(readableError(const FormatException('Unexpected character')), 'The server sent an unexpected reply. Please try again.');
    expect(readableError(const ReceiptException('This file type is not supported.')), 'This file type is not supported.');
    expect(readableError(StateError('bug')), 'Something went wrong. Please try again.');
  });

  test('describeError puts what failed before why', () {
    expect(
      describeError("Couldn't load the rooms", http.ClientException('x')),
      "Couldn't load the rooms. Can't reach the server. Check your internet connection and try again.",
    );
  });
}
