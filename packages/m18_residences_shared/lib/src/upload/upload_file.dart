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

/// A picked or pasted file: its name (only shown, the type is sniffed) and its bytes.
typedef PickedFile = ({String name, Uint8List bytes});

/// The extension (one of [extensions]) for a pasted file of MIME type [type], or `null` when it isn't allowed.
String? pastedFileExtension(String type, List<String> extensions) {
  final extension = switch (type.toLowerCase()) {
    'image/jpeg' || 'image/jpg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    'image/avif' => 'avif',
    'image/heic' => 'heic',
    'image/heif' => 'heif',
    'application/pdf' => 'pdf',
    _ => null,
  };
  return extensions.contains(extension) ? extension : null;
}

/// The name of a pasted file: its own [name] when it has a real one, else `pasted-<yyyyMMdd-HHmmss>.<extension>`
/// (clipboard pictures are often just "image.png").
String pastedFileName(String name, String extension, DateTime now) {
  if (name.isNotEmpty && name.toLowerCase() != 'image.$extension') return name;
  String two(int n) => n.toString().padLeft(2, '0');
  return 'pasted-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}.$extension';
}

/// Most pictures one upload can combine ([prepareReceipts]).
const maxCombinedPictures = 5;

/// Where each of several pictures of [sizes] (width, height) goes when they are stacked top to bottom into one: a
/// common width (the widest picture, at most [maxWidth]), each picture scaled to fit it (never enlarged) and
/// centred, [gap] px between them. When the stack would be taller than [maxHeight] (WebP allows 16,383 px),
/// everything is scaled down to fit.
({int width, int height, List<({int x, int y, int width, int height})> boxes}) stackLayout(
  List<(int, int)> sizes, {
  int maxWidth = 1600,
  int maxHeight = 16000,
  int gap = 16,
}) {
  if (sizes.isEmpty) return (width: 0, height: 0, boxes: const []);
  final width = math.min(maxWidth, sizes.map((s) => s.$1).reduce(math.max)).toDouble();
  final scaled = [for (final (w, h) in sizes) (w * math.min(1.0, width / w), h * math.min(1.0, width / w))];
  final total = scaled.fold(0.0, (sum, s) => sum + s.$2) + gap * (sizes.length - 1);
  final k = math.min(1.0, maxHeight / total);
  final canvasWidth = math.max(1, (width * k).round());
  final boxes = <({int x, int y, int width, int height})>[];
  var y = 0.0;
  for (final (w, h) in scaled) {
    final boxWidth = math.max(1, (w * k).round());
    final boxHeight = math.max(1, (h * k).round());
    boxes.add((x: ((canvasWidth - boxWidth) / 2).round(), y: y.round(), width: boxWidth, height: boxHeight));
    y += h * k + gap * k;
  }
  final last = boxes.last;
  return (width: canvasWidth, height: math.min(maxHeight, last.y + last.height), boxes: boxes);
}

/// The name of a picture combined from [names]: `<first name>-and-<n-1>-more.<extension>` (just the first name, with
/// [extension], for one).
String combinedFileName(List<String> names, String extension) {
  final first = names.first;
  final dot = first.lastIndexOf('.');
  final base = dot > 0 ? first.substring(0, dot) : first;
  return names.length == 1 ? '$base.$extension' : '$base-and-${names.length - 1}-more.$extension';
}
