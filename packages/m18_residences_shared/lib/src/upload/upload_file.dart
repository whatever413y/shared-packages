import 'dart:math' as math;
import 'dart:typed_data';

/// File types the receipt and payment pickers offer.
const receiptExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'avif', 'heic', 'heif', 'pdf'];

/// The server refuses receipt and payment uploads over 10 MiB.
const maxReceiptBytes = 10 * 1024 * 1024;

/// The server refuses payment QR images over 2 MiB.
const maxQrBytes = 2 * 1024 * 1024;

/// A receipt or payment image ready to upload (see `prepareReceipt`).
class PreparedReceipt {
  final Uint8List bytes;
  final String filename;
  final String contentType;

  /// Size of the picked file before conversion.
  final int originalSize;

  const PreparedReceipt({required this.bytes, required this.filename, required this.contentType, required this.originalSize});

  bool get wasConverted => bytes.length != originalSize;
}

/// A picked file that can't be uploaded; [message] is shown to the user.
class ReceiptException implements Exception {
  final String message;

  const ReceiptException(this.message);

  @override
  String toString() => message;
}

/// A file's real type from its first bytes (the same rules as the server), or `null` if it isn't a receipt type.
String? sniffReceiptType(Uint8List b) {
  bool startsWith(List<int> prefix, [int offset = 0]) {
    if (b.length < offset + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (b[offset + i] != prefix[i]) return false;
    }
    return true;
  }

  if (startsWith([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'image/png';
  if (startsWith('GIF87a'.codeUnits) || startsWith('GIF89a'.codeUnits)) return 'image/gif';
  if (startsWith('RIFF'.codeUnits) && startsWith('WEBP'.codeUnits, 8)) return 'image/webp';
  if (startsWith('%PDF-'.codeUnits)) return 'application/pdf';
  if (b.length >= 16 && startsWith('ftyp'.codeUnits, 4)) {
    final size = ByteData.sublistView(b, 0, 4).getUint32(0);
    final end = math.min(math.max(size, 16), b.length);
    final brands = [String.fromCharCodes(b.sublist(8, 12))];
    for (var i = 16; i + 4 <= end; i += 4) {
      brands.add(String.fromCharCodes(b.sublist(i, i + 4)));
    }
    if (brands.any((brand) => brand == 'avif' || brand == 'avis')) return 'image/avif';
    if (brands.any(const {'heic', 'heix', 'hevc', 'hevx', 'heim', 'heis', 'mif1', 'msf1'}.contains)) return 'image/heic';
  }
  return null;
}
