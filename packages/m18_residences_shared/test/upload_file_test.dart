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
    await expectLater(readClipboardFile(receiptExtensions), throwsUnsupportedError);
    await expectLater(pickFiles(receiptExtensions), throwsUnsupportedError);
    await expectLater(
      prepareReceipts([
        (name: 'a.jpg', bytes: bytes([0xFF, 0xD8, 0xFF])),
      ]),
      throwsUnsupportedError,
    );
  });

  group('stackLayout', () {
    test('stacks pictures at the widest width, smaller ones centred and never enlarged', () {
      final layout = stackLayout([(1200, 800), (600, 400)]);
      expect(layout.width, 1200);
      expect(layout.boxes, [(x: 0, y: 0, width: 1200, height: 800), (x: 300, y: 816, width: 600, height: 400)]);
      expect(layout.height, 1216);
    });

    test('shrinks pictures wider than the maximum to it', () {
      final layout = stackLayout([(3200, 1600), (1600, 1600)]);
      expect(layout.width, 1600);
      expect(layout.boxes.first, (x: 0, y: 0, width: 1600, height: 800));
      expect(layout.boxes.last, (x: 0, y: 816, width: 1600, height: 1600));
    });

    test('scales everything down when the stack would be taller than the maximum', () {
      final layout = stackLayout([(1000, 9000), (1000, 9000)], maxHeight: 16000);
      expect(layout.height, lessThanOrEqualTo(16000));
      expect(layout.width, lessThan(1000));
      expect(layout.boxes.last.y + layout.boxes.last.height, layout.height);
    });

    test('nothing to stack', () => expect(stackLayout([]).boxes, isEmpty));
  });

  test('combinedFileName names the result after the first picture', () {
    expect(combinedFileName(['gcash.png'], 'webp'), 'gcash.webp');
    expect(combinedFileName(['gcash.png', 'b.jpg', 'c.heic'], 'webp'), 'gcash-and-2-more.webp');
    expect(combinedFileName(['noext', 'b.jpg'], 'jpg'), 'noext-and-1-more.jpg');
  });

  test('pastedFileExtension accepts only the allowed types', () {
    expect(pastedFileExtension('image/png', receiptExtensions), 'png');
    expect(pastedFileExtension('IMAGE/JPEG', receiptExtensions), 'jpg');
    expect(pastedFileExtension('application/pdf', receiptExtensions), 'pdf');
    expect(pastedFileExtension('application/pdf', ['png', 'jpg']), isNull);
    expect(pastedFileExtension('text/plain', receiptExtensions), isNull);
  });

  test('pastedFileName keeps a real name and names clipboard pictures by time', () {
    final now = DateTime(2026, 11, 6, 9, 5, 3);
    expect(pastedFileName('gcash receipt.jpg', 'jpg', now), 'gcash receipt.jpg');
    expect(pastedFileName('image.png', 'png', now), 'pasted-20261106-090503.png');
    expect(pastedFileName('', 'png', now), 'pasted-20261106-090503.png');
  });
}
