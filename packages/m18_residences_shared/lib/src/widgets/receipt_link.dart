import 'package:flutter/material.dart';

import '../models/signed_file.dart';
import 'signed_image_dialog.dart';

/// Underlined link to a bill's receipt that opens it in a [SignedImageDialog] (images inline, PDFs in a new tab).
/// Renders nothing when there is no receipt (null or empty URL) or no tenant name.
class ReceiptLink extends StatelessWidget {
  final String? tenantName;
  final String? receiptUrl;

  /// Typically `AuthApi.signedReceiptUrl`.
  final Future<SignedFile> Function(String tenantName, String filename) fetchSignedFile;

  const ReceiptLink({super.key, required this.tenantName, required this.receiptUrl, required this.fetchSignedFile});

  @override
  Widget build(BuildContext context) {
    final url = receiptUrl;
    final name = tenantName;
    if (url == null || url.isEmpty || name == null) return const SizedBox.shrink();

    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final label = segments.isNotEmpty ? segments.last : url;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => SignedImageDialog.show(context, fetchFile: () => fetchSignedFile(name, url), subject: 'receipt'),
        child: Text(
          label,
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}
