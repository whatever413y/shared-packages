import 'package:flutter/material.dart';

import '../models/signed_file.dart';
import 'signed_image_dialog.dart';

/// Underlined link to a bill's receipt that opens it in a [SignedImageDialog] (images inline, PDFs in a new tab,
/// Save in the header). Renders nothing when there is no receipt (null or empty URL) or no tenant name.
class ReceiptLink extends StatelessWidget {
  final String? tenantName;
  final String? receiptUrl;

  /// Typically `AuthApi.signedReceiptUrl`.
  final Future<SignedFile> Function(String tenantName, String filename) fetchSignedFile;

  /// Shows the whole storage key (`receipts/<tenant name>/<file>`) instead of only the file name.
  final bool showFullName;

  const ReceiptLink({super.key, required this.tenantName, required this.receiptUrl, required this.fetchSignedFile, this.showFullName = false});

  /// Characters file systems refuse in a saved file's name.
  static final _unsafe = RegExp(r'[\\/:*?"<>|]');

  @override
  Widget build(BuildContext context) {
    final url = receiptUrl;
    final name = tenantName;
    if (url == null || url.isEmpty || name == null) return const SizedBox.shrink();

    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final fileName = segments.isNotEmpty ? segments.last : url;
    final key = 'receipts/$name/$url';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => SignedImageDialog.show(
          context,
          fetchFile: () => fetchSignedFile(name, url),
          subject: 'receipt',
          fileName: key,
          saveName: 'receipt-$name-$fileName'.replaceAll(_unsafe, '_'),
        ),
        child: Text(
          showFullName ? key : fileName,
          softWrap: true,
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}
