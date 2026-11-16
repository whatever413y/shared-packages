import '../upload/upload_file.dart';

/// Files pasted into the page. Outside a browser (tests) nothing is ever pasted.
Stream<PickedFile> pastedFiles(List<String> extensions, {void Function(String message)? onRejected}) => const Stream.empty();

/// Reads a picture from the clipboard. Outside a browser (tests) there is no clipboard to read.
Future<PickedFile?> readClipboardFile(List<String> extensions) async => throw UnsupportedError('Reading the clipboard needs a browser');
