import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../api/readable_error.dart';
import '../upload/upload_file.dart';
import '../web/paste_file.dart';
import '../web/pick_file.dart';
import 'modal.dart';

/// Asks for a file to attach: a modal ([showAppModal]) titled [title] whose main area chooses a file with the
/// browser's picker; a copied picture can be pasted instead (Ctrl+V / ⌘V while it is open, or its Paste button,
/// which reads the clipboard: phones have no Ctrl+V). Only [extensions] are accepted.
///
/// The chosen or pasted file shows as a preview while attaching: choosing or pasting again changes it, Remove
/// clears it. Save returns it; Close returns `null`. (Files already saved are opened with their View buttons, not
/// here.)
///
/// Paste works only while the modal is open, so a screen with several upload fields never has to guess which one
/// a paste is for.
///
/// Test ids: `attach-choose-file` (the area), `attach-paste`, `attach-save`, `attach-remove`, `attach-preview`.
Future<PickedFile?> pickOrPasteFile(BuildContext context, List<String> extensions, {required String title}) async {
  final files = await showAppModal<List<PickedFile>>(
    context,
    builder: (context) => AttachFileSheet(title: title, extensions: extensions),
  );
  return files?.first;
}

/// Like [pickOrPasteFile], but up to [maxFiles] pictures can be gathered (several picked at once, or chosen and
/// pasted one after another), to be combined into one upload ([prepareReceipts]). Each choose or paste adds; the
/// pictures show as numbered thumbnails (their order in the combined picture) that can be moved earlier or later
/// and removed one by one. A PDF can only be attached on its own. Save returns them in order; Close returns `null`.
///
/// Test ids: those of [pickOrPasteFile], plus `attach-thumb-<n>`, `attach-remove-<n>` (n from 1) and `attach-add`.
Future<List<PickedFile>?> pickOrPasteFiles(
  BuildContext context,
  List<String> extensions, {
  required String title,
  int maxFiles = maxCombinedPictures,
}) => showAppModal<List<PickedFile>>(
  context,
  builder: (context) => AttachFileSheet(title: title, extensions: extensions, maxFiles: maxFiles),
);

/// The content of [pickOrPasteFile]'s and [pickOrPasteFiles]' modal; pops with the files once saved. [maxFiles] 1
/// is the single-file chooser (a new file replaces the one shown).
class AttachFileSheet extends StatefulWidget {
  final String title;
  final List<String> extensions;
  final int maxFiles;

  const AttachFileSheet({super.key, required this.title, required this.extensions, this.maxFiles = 1});

  @override
  State<AttachFileSheet> createState() => _AttachFileSheetState();
}

class _AttachFileSheetState extends State<AttachFileSheet> {
  StreamSubscription<PickedFile>? _pastes;
  final List<PickedFile> _files = [];
  String? _error;
  bool _reading = false;

  bool get _multiple => widget.maxFiles > 1;
  bool get _apple => defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
  bool get _touch => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  bool get _full => _files.length >= widget.maxFiles;

  @override
  void initState() {
    super.initState();
    _pastes = pastedFiles(
      widget.extensions,
      onRejected: _fail,
    ).listen((file) => _add([file]), onError: (Object e) => _fail(describeError('Could not read the pasted file', e)));
  }

  @override
  void dispose() {
    _pastes?.cancel();
    super.dispose();
  }

  static bool _isPdf(PickedFile file) => sniffReceiptType(file.bytes) == 'application/pdf';

  /// Shows [files]: in the single chooser the first replaces the file shown; otherwise they are added after the
  /// others, as long as there is room and no PDF would be combined with anything.
  void _add(List<PickedFile> files) {
    if (!mounted || files.isEmpty) return;
    if (!_multiple) {
      return setState(() {
        _files
          ..clear()
          ..add(files.first);
        _error = null;
      });
    }
    final next = [..._files, ...files];
    if (next.length > 1 && next.any(_isPdf)) return _fail("A PDF can't be combined with pictures; attach it on its own");
    if (next.length > widget.maxFiles) return _fail('At most ${widget.maxFiles} pictures can be combined into one upload');
    setState(() {
      _files
        ..clear()
        ..addAll(next);
      _error = null;
    });
  }

  void _fail(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _paste() async {
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final file = await readClipboardFile(widget.extensions);
      if (file != null) return _add([file]);
      _fail(
        _touch ? 'No picture on the clipboard. Copy one first, then tap Paste.' : 'No picture on the clipboard. Copy one first, then paste it here.',
      );
    } catch (e) {
      _fail(describeError('Could not read the clipboard', e));
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _choose() async {
    setState(() => _error = null);
    final List<PickedFile>? files;
    try {
      files = _multiple
          ? await pickFiles(widget.extensions)
          : switch (await pickFile(widget.extensions)) {
              final file? => [file],
              null => null,
            };
    } catch (e) {
      return _fail(describeError('Could not open the file picker', e));
    }
    // Cancelling the picker keeps the files shown before (if any).
    if (files != null) _add(files);
  }

  void _move(int index, int by) => setState(() {
    final file = _files.removeAt(index);
    _files.insert(index + by, file);
  });

  void _save() {
    if (_files.isEmpty) return;
    _pastes?.cancel();
    _pastes = null;
    Navigator.of(context).pop(List<PickedFile>.unmodifiable(_files));
  }

  static String _size(int bytes) => bytes >= 1024 * 1024 ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB' : '${(bytes / 1024).ceil()} KB';

  String get _pasteHint => _touch ? 'or copy a picture and tap Paste' : 'or paste a copied picture with ${_apple ? '⌘V' : 'Ctrl+V'}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final thumbnails = _files.length > 1;
    return AppModal(
      title: widget.title,
      leading: AppModal.icon(context, Icons.attach_file),
      actions: [
        Semantics(
          container: true,
          identifier: 'attach-paste',
          child: OutlinedButton.icon(
            onPressed: _reading ? null : _paste,
            icon: _reading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.content_paste),
            label: const Text('Paste'),
          ),
        ),
        Semantics(
          container: true,
          identifier: 'attach-save',
          child: FilledButton.icon(onPressed: _files.isEmpty ? null : _save, icon: const Icon(Icons.check), label: const Text('Save')),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (thumbnails) _thumbnails(theme) else _area(theme),
          // Under the pictures, not in the footer: three footer buttons don't fit a 360 px phone.
          if (_files.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Semantics(
                container: true,
                identifier: 'attach-remove',
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: () => setState(() {
                    _files.clear();
                    _error = null;
                  }),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(thumbnails ? 'Remove all' : 'Remove'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            [
              'Accepted: ${widget.extensions.where((e) => e != 'jpeg' && e != 'heif').map((e) => e.toUpperCase()).join(', ')}.',
              if (_multiple) 'Up to ${widget.maxFiles} pictures, combined into one in this order; a PDF goes on its own.',
            ].join(' '),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error)),
            ),
        ],
      ),
    );
  }

  /// The main area for no file or one file: tapping it chooses (adds, in the multiple chooser).
  Widget _area(ThemeData theme) {
    final scheme = theme.colorScheme;
    final file = _files.firstOrNull;
    return Semantics(
      container: true,
      identifier: 'attach-choose-file',
      button: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _choose,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: file == null ? _empty(theme) : _preview(theme, file),
          ),
        ),
      ),
    );
  }

  Widget _empty(ThemeData theme) => Column(
    children: [
      Icon(Icons.upload_file, size: 36, color: theme.colorScheme.primary),
      const SizedBox(height: 10),
      Text(_multiple ? 'Choose files' : 'Choose a file', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(
        _pasteHint,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    ],
  );

  /// A file's picture (a PDF or HEIC, which the browser can't show here, as an icon).
  Widget _image(ThemeData theme, PickedFile file, {double iconSize = 48, BoxFit fit = BoxFit.contain}) {
    final type = sniffReceiptType(file.bytes);
    final icon = Icon(
      type == 'application/pdf' ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
      size: iconSize,
      color: theme.colorScheme.primary,
    );
    if (type == null || !type.startsWith('image/') || type == 'image/heic') return Center(child: icon);
    return Image.memory(
      file.bytes,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Center(child: icon),
    );
  }

  /// The one chosen or pasted file: its picture, its name and size, and how to change it (or add more).
  Widget _preview(ThemeData theme, PickedFile file) {
    final scheme = theme.colorScheme;
    final verb = _touch ? 'Tap' : 'Click';
    final change = _multiple && !_isPdf(file) ? '$verb to add more, $_pasteHint' : '$verb to choose another, $_pasteHint';
    return Column(
      children: [
        Semantics(
          container: true,
          identifier: 'attach-preview',
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _image(theme, file)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${file.name} · ${_size(file.bytes.length)}',
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        const SizedBox(height: 4),
        Text(
          change,
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Several pictures: numbered thumbnails (their order in the combined picture) with move and remove buttons,
  /// and an Add tile while there is room.
  Widget _thumbnails(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      identifier: 'attach-preview',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (i, file) in _files.indexed) _thumbnail(theme, i, file),
                  if (!_full)
                    Semantics(
                      container: true,
                      identifier: 'attach-add',
                      button: true,
                      child: SizedBox(
                        width: 112,
                        height: 148,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _choose,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.add_photo_alternate_outlined), SizedBox(height: 6), Text('Add')],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${_files.length} pictures, combined top to bottom in this order${_full ? '' : '; $_pasteHint'}',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(ThemeData theme, int index, PickedFile file) {
    final scheme = theme.colorScheme;
    final n = index + 1;
    Widget small(IconData icon, String tooltip, VoidCallback? onPressed, {String? id, Color? color}) {
      final button = IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
        style: IconButton.styleFrom(minimumSize: const Size(36, 36), padding: EdgeInsets.zero),
      );
      return id == null ? button : Semantics(container: true, identifier: id, child: button);
    }

    return Semantics(
      container: true,
      identifier: 'attach-thumb-$n',
      label: 'Picture $n of ${_files.length}: ${file.name}',
      child: Container(
        width: 112,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _image(theme, file, iconSize: 36, fit: BoxFit.cover),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: scheme.primary,
                      child: Text(
                        '$n',
                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                small(Icons.chevron_left, 'Move earlier', index == 0 ? null : () => _move(index, -1)),
                small(
                  Icons.close,
                  'Remove picture $n',
                  () => setState(() {
                    _files.removeAt(index);
                    _error = null;
                  }),
                  id: 'attach-remove-$n',
                  color: scheme.error,
                ),
                small(Icons.chevron_right, 'Move later', index == _files.length - 1 ? null : () => _move(index, 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
