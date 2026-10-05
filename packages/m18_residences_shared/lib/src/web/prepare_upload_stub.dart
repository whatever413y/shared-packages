import 'dart:typed_data';

import '../upload/upload_file.dart';

/// Shrinks and re-encodes a picked receipt or payment image. Outside a browser (tests) there is no image decoder.
Future<PreparedReceipt> prepareReceipt(String filename, Uint8List bytes) async => throw UnsupportedError('Preparing $filename needs a browser');

/// Prepares a payment QR image as PNG. Outside a browser (tests) there is no image decoder.
Future<Uint8List> prepareQrPng(Uint8List bytes) async => throw UnsupportedError('Preparing a QR image needs a browser');
