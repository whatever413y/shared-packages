import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../upload/upload_file.dart';
import 'api_exception.dart';

/// One plain sentence for [error], to show people instead of `'$error'` (the raw error goes to the console).
String readableError(Object error) {
  debugPrint('Error: $error');
  return switch (error) {
    ApiException(statusCode: 401) => 'Your session has ended. Please log in again.',
    ApiException(statusCode: 403) => "You don't have access to this.",
    ApiException(statusCode: 413) => 'The file is too large.',
    ApiException(statusCode: 429) => 'Too many attempts. Please wait a minute and try again.',
    ApiException(:final statusCode) when statusCode >= 500 => 'Something went wrong on our side. Please try again in a moment.',
    // The server's 4xx messages are written for people ("This bill changed meanwhile. Reload and try again.").
    ApiException(:final message) when message.trim().isNotEmpty => _sentence(message),
    http.ClientException() => "Can't reach the server. Check your internet connection and try again.",
    TimeoutException() => 'The server is taking too long to answer. Please try again.',
    FormatException() => 'The server sent an unexpected reply. Please try again.',
    ReceiptException(:final message) => message,
    _ => 'Something went wrong. Please try again.',
  };
}

/// What failed and why, e.g. `describeError("Couldn't load the rooms", e)` →
/// "Couldn't load the rooms. Can't reach the server. Check your internet connection and try again."
String describeError(String action, Object error) => '${_sentence(action)} ${readableError(error)}';

String _sentence(String text) {
  final trimmed = text.trim();
  return RegExp(r'[.!?]$').hasMatch(trimmed) ? trimmed : '$trimmed.';
}
