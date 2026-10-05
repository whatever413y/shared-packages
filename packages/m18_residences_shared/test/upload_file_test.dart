import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:m18_residences_shared/m18_residences_shared.dart';

Uint8List bytes(List<int> head) => Uint8List.fromList([...head, ...List.filled(16, 0)]);

void main() {
  test('sniffReceiptType reads the type from the first bytes, as the server does', () {
    expect(sniffReceiptType(bytes([0xFF, 0xD8, 0xFF])), 'image/jpeg');
    expect(sniffReceiptType(bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])), 'image/png');
    expect(sniffReceiptType(bytes('GIF89a'.codeUnits)), 'image/gif');
    expect(sniffReceiptType(bytes([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits])), 'image/webp');
    expect(sniffReceiptType(bytes('%PDF-1.7'.codeUnits)), 'application/pdf');
    expect(sniffReceiptType(bytes([0, 0, 0, 16, ...'ftypavif'.codeUnits])), 'image/avif');
    expect(sniffReceiptType(bytes([0, 0, 0, 16, ...'ftypheic'.codeUnits])), 'image/heic');
    expect(sniffReceiptType(bytes('MZ'.codeUnits)), isNull);
    expect(sniffReceiptType(Uint8List(0)), isNull);
  });

  test('outside a browser, preparing and picking files is unsupported', () async {
    await expectLater(prepareReceipt('a.jpg', bytes([0xFF, 0xD8, 0xFF])), throwsUnsupportedError);
    await expectLater(prepareQrPng(Uint8List(0)), throwsUnsupportedError);
    await expectLater(pickFile(receiptExtensions), throwsUnsupportedError);
  });
}
