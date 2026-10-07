import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../models/signed_file.dart';
import 'app_theme.dart';
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

  /// A round icon button (tooltip "View receipt"/"View payment") instead of the labeled one, for dense tables.
  final bool iconOnly;

  /// The button's text instead of "View receipt"/"View payment" (e.g. "View" in a row that names the file); the full
  /// name is then its tooltip.
  final String? label;

  const BillFileButton({
    super.key,
    required this.kind,
    required this.tenantName,
    required this.fileUrl,
    required this.fetchSignedFile,
    this.iconOnly = false,
    this.label,
  });

  /// Characters file systems refuse in a saved file's name.
  static final _unsafe = RegExp(r'[\\/:*?"<>|]');

  @override
  Widget build(BuildContext context) {
    final url = fileUrl;
    final name = tenantName;
    if (url == null || url.isEmpty || name == null) return const SizedBox.shrink();

    final subject = kind.subject;
    final title = '${subject[0].toUpperCase()}${subject.substring(1)}';
    void open() => SignedImageDialog.show(
      context,
      fetchFile: () => fetchSignedFile(name, url),
      subject: subject,
      fileName: '$title · $name',
      saveName: '$subject-$name-$url'.replaceAll(_unsafe, '_'),
    );
    if (iconOnly) return IconButton(tooltip: 'View $subject', onPressed: open, icon: Icon(kind.icon));
    final button = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: open,
      icon: Icon(kind.icon),
      label: Text(label ?? 'View $subject'),
    );
    return label == null ? button : Tooltip(message: 'View $subject', child: button);
  }
}

/// A bill's [BillStatus] as a coloured label: red Unpaid, amber For verification, green Paid ([StatusColors],
/// AA contrast in light and dark).
class BillStatusChip extends StatelessWidget {
  final BillStatus status;

  /// A larger chip, for headers.
  final bool large;

  const BillStatusChip(this.status, {super.key, this.large = false});

  static IconData icon(BillStatus status) => switch (status) {
    BillStatus.unpaid => Icons.error_outline,
    BillStatus.forVerification => Icons.hourglass_top,
    BillStatus.paid => Icons.check_circle_outline,
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = StatusColors.of(context).forStatus(status);
    final textStyle = (large ? Theme.of(context).textTheme.labelLarge : Theme.of(context).textTheme.labelMedium)!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: large ? 6 : 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon(status), size: large ? 18 : 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label,
              style: textStyle.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
