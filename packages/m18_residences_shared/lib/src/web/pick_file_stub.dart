import 'dart:typed_data';

/// Opens the browser's file picker. Outside a browser (tests) there is nothing to pick from.
Future<({String name, Uint8List bytes})?> pickFile(List<String> extensions) async => throw UnsupportedError('Picking a file needs a browser');
