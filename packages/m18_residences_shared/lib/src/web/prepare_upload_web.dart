import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../upload/upload_file.dart';

/// Images are shrunk to at most this many pixels on their long edge.
const _maxEdge = 1600;
const _quality = 0.8;

/// The HEIC decoder (heic-to, LGPL-3.0), this package's asset `assets/heic-to/`, loaded only when needed.
const _heicDecoderUrl = 'assets/packages/m18_residences_shared/assets/heic-to/heic-to.js';

/// Prepares a picked receipt or payment image for upload: images (including HEIC) are shrunk and re-encoded as WebP
/// (JPEG where the browser can't write WebP); a WebP already smaller than its re-encoding is kept as it is.
/// PDFs are kept as they are.
Future<PreparedReceipt> prepareReceipt(String filename, Uint8List bytes) async {
  final type = sniffReceiptType(bytes);
  if (type == null) {
    throw const ReceiptException('Unsupported file: pick an image (JPEG, PNG, WebP, GIF, AVIF, HEIC) or a PDF');
  }

  if (type == 'application/pdf') {
    if (bytes.length > maxReceiptBytes) throw const ReceiptException('The PDF is larger than 10 MB');
    return PreparedReceipt(bytes: bytes, filename: filename, contentType: type, originalSize: bytes.length);
  }

  final bitmap = type == 'image/heic' ? await _decodeHeic(bytes) : await _decode(bytes, type);
  final (encoded, encodedType) = await _encode(bitmap, maxEdge: _maxEdge, type: 'image/webp');

  // Re-encoding a small WebP can only make it bigger (and blurrier).
  if (type == 'image/webp' && bytes.length <= encoded.length) {
    if (bytes.length > maxReceiptBytes) throw const ReceiptException('The image is larger than 10 MB');
    return PreparedReceipt(bytes: bytes, filename: filename, contentType: type, originalSize: bytes.length);
  }
  if (encoded.length > maxReceiptBytes) throw const ReceiptException('The image is still larger than 10 MB after shrinking it');
  final extension = encodedType == 'image/webp' ? 'webp' : 'jpg';
  return PreparedReceipt(bytes: encoded, filename: '${_baseName(filename)}.$extension', contentType: encodedType, originalSize: bytes.length);
}

/// Prepares several picked receipt or payment pictures as one upload: a single file goes through [prepareReceipt];
/// several pictures (no PDF among them) are stacked top to bottom into one image ([stackLayout]) and encoded like a
/// single picture (WebP, JPEG where the browser can't write WebP).
Future<PreparedReceipt> prepareReceipts(List<PickedFile> files) async {
  if (files.isEmpty) throw const ReceiptException('Pick at least one picture');
  if (files.length == 1) return prepareReceipt(files.first.name, files.first.bytes);
  if (files.length > maxCombinedPictures) throw const ReceiptException('At most $maxCombinedPictures pictures can be combined');

  final bitmaps = <web.ImageBitmap>[];
  try {
    for (final file in files) {
      final type = sniffReceiptType(file.bytes);
      if (type == null) throw ReceiptException('Unsupported file: ${file.name}');
      if (type == 'application/pdf') throw const ReceiptException("A PDF can't be combined with pictures; attach it on its own");
      bitmaps.add(type == 'image/heic' ? await _decodeHeic(file.bytes) : await _decode(file.bytes, type));
    }
    final layout = stackLayout([for (final b in bitmaps) (b.width, b.height)], maxWidth: _maxEdge);
    final canvas = web.OffscreenCanvas(layout.width, layout.height);
    final context = canvas.getContext('2d') as web.OffscreenCanvasRenderingContext2D
      ..fillStyle = 'white'.toJS
      ..fillRect(0, 0, layout.width, layout.height);
    for (final (i, box) in layout.boxes.indexed) {
      context.drawImage(bitmaps[i], box.x, box.y, box.width, box.height);
    }
    final (encoded, encodedType) = await _encodeCanvas(canvas, 'image/webp');
    if (encoded.length > maxReceiptBytes) throw const ReceiptException('The combined picture is larger than 10 MB; use fewer or smaller pictures');
    return PreparedReceipt(
      bytes: encoded,
      filename: combinedFileName([for (final f in files) f.name], encodedType == 'image/webp' ? 'webp' : 'jpg'),
      contentType: encodedType,
      originalSize: files.fold(0, (sum, f) => sum + f.bytes.length),
    );
  } finally {
    for (final bitmap in bitmaps) {
      bitmap.close();
    }
  }
}

/// Payment QR images are shrunk to at most this many pixels on their long edge.
const _qrMaxEdge = 1024;

/// Prepares a picked payment QR image for upload: decoded by the browser (HEIC too), shrunk to at most
/// [_qrMaxEdge] px and encoded as PNG, which keeps a QR code's edges sharp.
Future<Uint8List> prepareQrPng(Uint8List bytes) async {
  final type = sniffReceiptType(bytes);
  if (type == null || type == 'application/pdf') {
    throw const ReceiptException('Unsupported file: pick an image (JPEG, PNG, WebP, GIF, AVIF, HEIC)');
  }
  final bitmap = type == 'image/heic' ? await _decodeHeic(bytes) : await _decode(bytes, type);
  // On white: a transparent QR code would vanish on a dark panel, and scanners need the light quiet zone.
  final (encoded, _) = await _encode(bitmap, maxEdge: _qrMaxEdge, type: 'image/png', background: 'white');
  if (encoded.length > maxQrBytes) throw const ReceiptException('The QR image is still larger than 2 MB as PNG; crop it to the QR code');
  return encoded;
}

Future<web.ImageBitmap> _decode(Uint8List bytes, String type) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: type));
  try {
    return await web.window.createImageBitmap(blob).toDart;
  } catch (_) {
    throw const ReceiptException("This browser can't read the image; try a JPEG or PNG");
  }
}

@JS('HeicTo')
external JSFunction? get _heicTo;

Future<web.ImageBitmap> _decodeHeic(Uint8List bytes) async {
  await _loadHeicDecoder();
  final options = JSObject()
    ..setProperty('blob'.toJS, web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/heic')))
    ..setProperty('type'.toJS, 'bitmap'.toJS);
  try {
    final promise = _heicTo!.callAsFunction(null, options) as JSPromise<web.ImageBitmap>;
    return await promise.toDart;
  } catch (_) {
    throw const ReceiptException("This HEIC photo couldn't be read; try exporting it as a JPEG");
  }
}

Future<void>? _heicDecoderLoading;

Future<void> _loadHeicDecoder() {
  if (_heicTo != null) return Future.value();
  return _heicDecoderLoading ??= () {
    final done = Completer<void>();
    final script = web.HTMLScriptElement()..src = _heicDecoderUrl;
    script.onload = ((web.Event _) => done.complete()).toJS;
    script.onerror = ((web.Event _) {
      _heicDecoderLoading = null;
      done.completeError(const ReceiptException("The HEIC decoder couldn't be loaded; check the connection and try again"));
    }).toJS;
    web.document.head!.append(script);
    return done.future;
  }();
}

/// Draws [bitmap] scaled to at most [maxEdge] px on its long edge (on [background] first, when given) and encodes it
/// ([_encodeCanvas]).
Future<(Uint8List, String)> _encode(web.ImageBitmap bitmap, {required int maxEdge, required String type, String? background}) async {
  final scale = math.min(1.0, maxEdge / math.max(bitmap.width, bitmap.height));
  final width = math.max(1, (bitmap.width * scale).round());
  final height = math.max(1, (bitmap.height * scale).round());
  final canvas = web.OffscreenCanvas(width, height);
  final context = canvas.getContext('2d') as web.OffscreenCanvasRenderingContext2D;
  if (background != null) {
    context.fillStyle = background.toJS;
    context.fillRect(0, 0, width, height);
  }
  context.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();
  return _encodeCanvas(canvas, type);
}

/// Encodes [canvas] as [type]; WebP falls back to JPEG where the browser can't write WebP.
Future<(Uint8List, String)> _encodeCanvas(web.OffscreenCanvas canvas, String type) async {
  var blob = await canvas.convertToBlob(web.ImageEncodeOptions(type: type, quality: _quality)).toDart;
  // Browsers that can't write WebP silently return PNG instead.
  if (type == 'image/webp' && blob.type != 'image/webp') {
    blob = await canvas.convertToBlob(web.ImageEncodeOptions(type: 'image/jpeg', quality: _quality)).toDart;
  }
  final bytes = (await blob.arrayBuffer().toDart).toDart.asUint8List();
  return (bytes, blob.type);
}

String _baseName(String filename) {
  final dot = filename.lastIndexOf('.');
  return dot > 0 ? filename.substring(0, dot) : filename;
}
