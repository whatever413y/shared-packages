import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/signed_file.dart';
import '../web/open_url.dart';
import '../web/save_file.dart';
import 'responsive.dart';
import 'selectable.dart';

/// Dialog showing a file behind a short-lived signed link; the link is fetched once when the dialog opens.
/// Images are shown in the dialog; PDFs get an "Open PDF" button that opens them in a new browser tab.
/// The header names the file and has Save (WebP/AVIF/GIF images are saved as JPEG), Open in new tab and Close.
class SignedImageDialog extends StatefulWidget {
  final Future<SignedFile> Function() fetchFile;

  /// What is being shown, used in the texts ("Error loading receipt: ...").
  final String subject;

  /// Shown in the header, e.g. the file's storage key; the [subject] when null.
  final String? fileName;

  /// Name of a saved copy, without extension; the [subject] when null.
  final String? saveName;

  /// Opens a link; a new browser tab by default.
  final void Function(String url) openUrl;

  /// Saves the file as a download; [saveSignedFile] by default.
  final Future<void> Function(SignedFile file, String baseName) saveFile;

  const SignedImageDialog({
    super.key,
    required this.fetchFile,
    this.subject = 'image',
    this.fileName,
    this.saveName,
    this.openUrl = openInNewTab,
    this.saveFile = saveSignedFile,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<SignedFile> Function() fetchFile,
    String subject = 'image',
    String? fileName,
    String? saveName,
    void Function(String url) openUrl = openInNewTab,
    Future<void> Function(SignedFile file, String baseName) saveFile = saveSignedFile,
  }) => showSelectableDialog<void>(
    context: context,
    builder: (_) =>
        SignedImageDialog(fetchFile: fetchFile, subject: subject, fileName: fileName, saveName: saveName, openUrl: openUrl, saveFile: saveFile),
  );

  @override
  State<SignedImageDialog> createState() => _SignedImageDialogState();
}

class _SignedImageDialogState extends State<SignedImageDialog> {
  late final Future<SignedFile> _file = widget.fetchFile();
  bool _saving = false;
  String? _saveError;

  Future<void> _save(SignedFile file) async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.saveFile(file, widget.saveName ?? widget.subject);
    } catch (e) {
      if (mounted) setState(() => _saveError = 'Saving the ${widget.subject} failed: ${e is ApiException ? e.message : e}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.windowSize.isCompact;
    return Dialog(
      insetPadding: compact ? const EdgeInsets.all(12) : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: FutureBuilder<SignedFile>(
          future: _file,
          builder: (context, snapshot) {
            final file = snapshot.connectionState == ConnectionState.done && !snapshot.hasError ? snapshot.data : null;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, file),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(_saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                Flexible(child: _body(context, snapshot)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, SignedFile? file) {
    final subject = widget.subject;
    final title = widget.fileName ?? '${subject[0].toUpperCase()}${subject.substring(1)}';
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              file?.isPdf ?? false ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Semantics(
            container: true,
            identifier: 'signed-file-save',
            child: IconButton(
              tooltip: 'Save',
              onPressed: file == null || _saving ? null : () => _save(file),
              icon: _saving ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
            ),
          ),
          IconButton(
            tooltip: 'Open in new tab',
            onPressed: file == null ? null : () => widget.openUrl(file.url),
            icon: const Icon(Icons.open_in_new),
          ),
          Semantics(
            container: true,
            identifier: 'signed-file-close',
            child: IconButton(tooltip: 'Close', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<SignedFile> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasError) {
      final error = snapshot.error;
      final reason = error is ApiException ? error.message : '$error';
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text('Error loading ${widget.subject}: $reason')),
      );
    }
    final file = snapshot.data!;
    if (file.isPdf) {
      // Opened from the button press, so browsers don't treat the new tab as a popup.
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This ${widget.subject} is a PDF.'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => widget.openUrl(file.url), icon: const Icon(Icons.open_in_new), label: const Text('Open PDF')),
          ],
        ),
      );
    }
    final size = MediaQuery.sizeOf(context);
    // The image on a neutral panel (receipts and QR codes are mostly white); pinch or scroll to zoom.
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(8),
      child: InteractiveViewer(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size.width * 0.9, maxHeight: size.height * 0.75),
          child: Image.network(
            file.url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Padding(padding: EdgeInsets.all(20), child: Text('Failed to load image')),
          ),
        ),
      ),
    );
  }
}
