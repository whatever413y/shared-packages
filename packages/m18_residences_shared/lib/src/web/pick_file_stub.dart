import 'dart:typed_data';

/// Opens the browser's file picker. Outside a browser (tests) there is nothing to pick from.
Future<({String name, Uint8List bytes})?> pickFile(List<String> extensions) async => throw UnsupportedError('Picking a file needs a browser');

/// Opens the browser's file picker for several files. Outside a browser (tests) there is nothing to pick from.
Future<List<({String name, Uint8List bytes})>?> pickFiles(List<String> extensions) async => throw UnsupportedError('Picking files needs a browser');
