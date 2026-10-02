import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/signed_file.dart';
import '../web/open_url.dart';

/// Dialog showing a file behind a short-lived signed link; the link is fetched once when the dialog opens.
/// Images are shown in the dialog; PDFs get an "Open PDF" button that opens them in a new browser tab.
class SignedImageDialog extends StatefulWidget {
  final Future<SignedFile> Function() fetchFile;

  /// What is being shown, used in the texts ("Error loading receipt: ...").
  final String subject;

  /// Opens a PDF link; a new browser tab by default.
  final void Function(String url) openUrl;

  const SignedImageDialog({super.key, required this.fetchFile, this.subject = 'image', this.openUrl = openInNewTab});

  static Future<void> show(
    BuildContext context, {
    required Future<SignedFile> Function() fetchFile,
    String subject = 'image',
    void Function(String url) openUrl = openInNewTab,
  }) => showDialog<void>(
    context: context,
    builder: (_) => SignedImageDialog(fetchFile: fetchFile, subject: subject, openUrl: openUrl),
  );

  @override
  State<SignedImageDialog> createState() => _SignedImageDialogState();
}

class _SignedImageDialogState extends State<SignedImageDialog> {
  late final Future<SignedFile> _file = widget.fetchFile();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: FutureBuilder<SignedFile>(
        future: _file,
        builder: (context, snapshot) {
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
          return InteractiveViewer(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.width * 0.9, maxHeight: size.height * 0.9),
              child: Image.network(
                file.url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(padding: EdgeInsets.all(20), child: Text('Failed to load image')),
              ),
            ),
          );
        },
      ),
    );
  }
}
