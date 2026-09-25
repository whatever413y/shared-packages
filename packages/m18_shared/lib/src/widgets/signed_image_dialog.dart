import 'package:flutter/material.dart';

import '../api/api_exception.dart';

/// Dialog showing an image behind a short-lived signed URL; the URL is fetched once when the dialog opens.
class SignedImageDialog extends StatefulWidget {
  final Future<String> Function() fetchUrl;

  /// What is being shown, used in the error text ("Error loading receipt: ...").
  final String subject;

  const SignedImageDialog({super.key, required this.fetchUrl, this.subject = 'image'});

  static Future<void> show(BuildContext context, {required Future<String> Function() fetchUrl, String subject = 'image'}) => showDialog<void>(
    context: context,
    builder: (_) => SignedImageDialog(fetchUrl: fetchUrl, subject: subject),
  );

  @override
  State<SignedImageDialog> createState() => _SignedImageDialogState();
}

class _SignedImageDialogState extends State<SignedImageDialog> {
  late final Future<String> _url = widget.fetchUrl();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: FutureBuilder<String>(
        future: _url,
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
          return InteractiveViewer(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.width * 0.9, maxHeight: size.height * 0.9),
              child: Image.network(
                snapshot.data!,
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
