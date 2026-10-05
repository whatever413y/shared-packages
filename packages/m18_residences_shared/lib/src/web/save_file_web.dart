import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../models/signed_file.dart';

/// Downloads [file] as `<baseName>.<SignedFile.saveExtension>`. Images phones and galleries may not open
/// (WebP, AVIF, GIF) are converted to JPEG in the browser first; JPEG, PNG and PDF are saved as they are.
Future<void> saveSignedFile(SignedFile file, String baseName) async {
  final response = await web.window.fetch(file.url.toJS).toDart;
  if (!response.ok) throw Exception('Download failed (HTTP ${response.status})');
  var blob = await response.blob().toDart;
  if (file.savesAsJpeg) blob = await _toJpeg(blob);

  final url = web.URL.createObjectURL(blob);
  try {
    final link = web.HTMLAnchorElement()
      ..href = url
      ..download = '$baseName.${file.saveExtension}'
      ..style.display = 'none';
    web.document.body!.append(link);
    link.click();
    link.remove();
  } finally {
    // The click has started the download; the URL is no longer needed.
    Future<void>.delayed(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  }
}

Future<web.Blob> _toJpeg(web.Blob image) async {
  final web.ImageBitmap bitmap;
  try {
    bitmap = await web.window.createImageBitmap(image).toDart;
  } catch (_) {
    throw Exception("This browser can't read the image to convert it");
  }
  final canvas = web.OffscreenCanvas(bitmap.width, bitmap.height);
  final context = canvas.getContext('2d') as web.OffscreenCanvasRenderingContext2D
    // JPEG has no transparency: transparent pixels become white, not black.
    ..fillStyle = 'white'.toJS
    ..fillRect(0, 0, bitmap.width, bitmap.height);
  context.drawImage(bitmap, 0, 0);
  bitmap.close();
  return canvas.convertToBlob(web.ImageEncodeOptions(type: 'image/jpeg', quality: 0.92)).toDart;
}
