import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../models/signed_file.dart';
import 'signed_image_dialog.dart';

/// The two files a bill can have.
enum BillFileKind {
  /// The owner's receipt (`receipts/<tenant name>/<file>`); makes the bill paid.
  receipt('receipt', Icons.receipt_long),

  /// The tenant's proof of payment (`tenant-payments/<tenant name>/<file>`).
  payment('payment', Icons.payments_outlined);

  /// Used in texts ("View receipt", "Error loading payment: ...") and saved file names.
  final String subject;
  final IconData icon;

  const BillFileKind(this.subject, this.icon);
}

/// "View receipt" / "View payment" button that opens the file in a [SignedImageDialog] (images inline, PDFs in a
/// new tab, Save in the header). No file name, key or link is shown. Renders nothing when there is no file (null or
/// empty) or no tenant name.
class BillFileButton extends StatelessWidget {
  final BillFileKind kind;
  final String? tenantName;

  /// The bill's `receiptUrl` or `paymentUrl` (a file name).
  final String? fileUrl;

  /// Typically `AuthApi.signedReceiptUrl` or `AuthApi.signedTenantPaymentUrl`.
  final Future<SignedFile> Function(String tenantName, String filename) fetchSignedFile;

  const BillFileButton({super.key, required this.kind, required this.tenantName, required this.fileUrl, required this.fetchSignedFile});

  /// Characters file systems refuse in a saved file's name.
  static final _unsafe = RegExp(r'[\\/:*?"<>|]');

  @override
  Widget build(BuildContext context) {
    final url = fileUrl;
    final name = tenantName;
    if (url == null || url.isEmpty || name == null) return const SizedBox.shrink();

    final subject = kind.subject;
    final title = '${subject[0].toUpperCase()}${subject.substring(1)}';
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: () => SignedImageDialog.show(
        context,
        fetchFile: () => fetchSignedFile(name, url),
        subject: subject,
        fileName: '$title · $name',
        saveName: '$subject-$name-$url'.replaceAll(_unsafe, '_'),
      ),
      icon: Icon(kind.icon),
      label: Text('View $subject'),
    );
  }
}

/// A bill's [BillStatus] as a coloured label: red Unpaid, amber For verification, green Paid (AA contrast).
class BillStatusChip extends StatelessWidget {
  final BillStatus status;

  const BillStatusChip(this.status, {super.key});

  static (Color, Color, IconData) _style(BillStatus status) => switch (status) {
    BillStatus.unpaid => (const Color(0xFFFFEBEE), const Color(0xFFB71C1C), Icons.error_outline),
    BillStatus.forVerification => (const Color(0xFFFFF3E0), const Color(0xFF8A4B00), Icons.hourglass_top),
    BillStatus.paid => (const Color(0xFFE8F5E9), const Color(0xFF1B5E20), Icons.check_circle_outline),
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
