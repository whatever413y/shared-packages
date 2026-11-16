import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../upload/upload_file.dart';

/// Files pasted into the page (Ctrl+V / ⌘V) while listened to: the first pasted file of one of [extensions].
///
/// Only a paste holding such a file is taken (its default action prevented); a text paste goes on into the focused
/// field as usual. A paste holding only files of other types calls [onRejected] with a message to show.
Stream<PickedFile> pastedFiles(List<String> extensions, {void Function(String message)? onRejected}) {
  late final StreamController<PickedFile> controller;
  void onPaste(web.Event event) {
    final files = (event as web.ClipboardEvent).clipboardData?.files;
    if (files == null || files.length == 0) return;
    for (var i = 0; i < files.length; i++) {
      final file = files.item(i)!;
      final extension = pastedFileExtension(file.type, extensions);
      if (extension == null) continue;
      event.preventDefault();
      final name = pastedFileName(file.name, extension, DateTime.now());
      file.arrayBuffer().toDart.then(
        (buffer) => controller.add((name: name, bytes: buffer.toDart.asUint8List())),
        onError: (Object error) => controller.addError(error),
      );
      return;
    }
    onRejected?.call("That file type isn't supported");
  }

  final listener = onPaste.toJS;
  controller = StreamController<PickedFile>(
    onListen: () => web.document.addEventListener('paste', listener),
    onCancel: () => web.document.removeEventListener('paste', listener),
  );
  return controller.stream;
}

/// Reads the first picture (or PDF) of one of [extensions] from the clipboard (the browser may ask for permission
/// first); `null` when the clipboard holds none. Call it from a button press (a user gesture).
Future<PickedFile?> readClipboardFile(List<String> extensions) async {
  final items = (await web.window.navigator.clipboard.read().toDart).toDart;
  for (final item in items) {
    for (final type in item.types.toDart.map((type) => type.toDart)) {
      final extension = pastedFileExtension(type, extensions);
      if (extension == null) continue;
      final blob = await item.getType(type).toDart;
      final buffer = await blob.arrayBuffer().toDart;
      return (name: pastedFileName('', extension, DateTime.now()), bytes: buffer.toDart.asUint8List());
    }
  }
  return null;
}
