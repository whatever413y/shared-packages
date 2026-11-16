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
Future<PickedFile?> pickOrPasteFile(BuildContext context, List<String> extensions, {required String title}) => showAppModal<PickedFile>(
  context,
  builder: (context) => AttachFileSheet(title: title, extensions: extensions),
);

/// The content of [pickOrPasteFile]'s modal; pops with the file once saved.
class AttachFileSheet extends StatefulWidget {
  final String title;
  final List<String> extensions;

  const AttachFileSheet({super.key, required this.title, required this.extensions});

  @override
  State<AttachFileSheet> createState() => _AttachFileSheetState();
}

class _AttachFileSheetState extends State<AttachFileSheet> {
  StreamSubscription<PickedFile>? _pastes;
  PickedFile? _file;
  String? _error;
  bool _reading = false;

  bool get _apple => defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;
  bool get _touch => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _pastes = pastedFiles(
      widget.extensions,
      onRejected: _fail,
    ).listen(_show, onError: (Object e) => _fail(describeError('Could not read the pasted file', e)));
  }

  @override
  void dispose() {
    _pastes?.cancel();
    super.dispose();
  }

  /// Shows [file] as the preview (replacing the one before); Save attaches it.
  void _show(PickedFile file) {
    if (!mounted) return;
    setState(() {
      _file = file;
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
      if (file != null) return _show(file);
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
    final PickedFile? file;
    try {
      file = await pickFile(widget.extensions);
    } catch (e) {
      return _fail(describeError('Could not open the file picker', e));
    }
    // Cancelling the picker keeps the file shown before (if any).
    if (file != null) _show(file);
  }

  void _save() {
    final file = _file;
    if (file == null) return;
    _pastes?.cancel();
    _pastes = null;
    Navigator.of(context).pop(file);
  }

  static String _size(int bytes) => bytes >= 1024 * 1024 ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB' : '${(bytes / 1024).ceil()} KB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final file = _file;
    final pasteHint = _touch ? 'or copy a picture and tap Paste' : 'or paste a copied picture with ${_apple ? '⌘V' : 'Ctrl+V'}';
    return AppModal(
      title: widget.title,
      leading: AppModal.icon(context, Icons.attach_file),
      actions: [
        if (file != null)
          Semantics(
            container: true,
            identifier: 'attach-remove',
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              onPressed: () => setState(() => _file = null),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove'),
            ),
          ),
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
          child: FilledButton.icon(onPressed: file == null ? null : _save, icon: const Icon(Icons.check), label: const Text('Save')),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
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
                  child: file == null ? _empty(theme, pasteHint) : _preview(theme, file, pasteHint),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Accepted: ${widget.extensions.where((e) => e != 'jpeg' && e != 'heif').map((e) => e.toUpperCase()).join(', ')}.',
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

  Widget _empty(ThemeData theme, String pasteHint) => Column(
    children: [
      Icon(Icons.upload_file, size: 36, color: theme.colorScheme.primary),
      const SizedBox(height: 10),
      Text('Choose a file', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(
        pasteHint,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    ],
  );

  /// The chosen or pasted file: the picture itself (a PDF or HEIC, which the browser can't show here, as an icon),
  /// its name and size, and how to change it.
  Widget _preview(ThemeData theme, PickedFile file, String pasteHint) {
    final scheme = theme.colorScheme;
    final type = sniffReceiptType(file.bytes);
    final icon = Icon(type == 'application/pdf' ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined, size: 48, color: scheme.primary);
    final showsImage = type != null && type.startsWith('image/') && type != 'image/heic';
    return Column(
      children: [
        Semantics(
          container: true,
          identifier: 'attach-preview',
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: showsImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(file.bytes, fit: BoxFit.contain, gaplessPlayback: true, errorBuilder: (_, _, _) => icon),
                  )
                : icon,
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
          '${_touch ? 'Tap' : 'Click'} to choose another, $pasteHint',
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
