import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../models/bill_file_kind.dart';
import '../models/signed_file.dart';
import 'app_theme.dart';
import 'signed_image_dialog.dart';

/// The icon of each [BillFileKind].
extension BillFileKindIcon on BillFileKind {
  IconData get icon => switch (this) {
    BillFileKind.receipt => Icons.receipt_long,
    BillFileKind.payment => Icons.payments_outlined,
  };
}

/// "View receipt" / "View payment" button that opens bill [billId]'s file in a [SignedImageDialog] (images inline,
/// PDFs in a new tab, Save in the header). No file name, key or link is shown. Renders nothing when the bill has no
/// such file ([fileUrl] null or empty).
class BillFileButton extends StatelessWidget {
  final BillFileKind kind;
  final int billId;

  /// The bill's `receiptUrl` or `paymentUrl`: whether it has the file (and part of a saved file's name).
  final String? fileUrl;

  /// The bill's tenant, for the dialog's title and the saved file's name (optional).
  final String? tenantName;

  /// Typically `AuthApi.signedBillFileUrl`.
  final Future<SignedFile> Function(int billId, BillFileKind kind) fetchSignedFile;

  /// A round icon button (tooltip "View receipt"/"View payment") instead of the labeled one, for dense tables.
  final bool iconOnly;

  /// The button's text instead of "View receipt"/"View payment" (e.g. "View" in a row that names the file); the full
  /// name is then its tooltip.
  final String? label;

  const BillFileButton({
    super.key,
    required this.kind,
    required this.billId,
    required this.fileUrl,
    required this.fetchSignedFile,
    this.tenantName,
    this.iconOnly = false,
    this.label,
  });

  /// Characters file systems refuse in a saved file's name.
  static final _unsafe = RegExp(r'[\\/:*?"<>|]');

  @override
  Widget build(BuildContext context) {
    final url = fileUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    final name = tenantName;
    final subject = kind.subject;
    final title = '${subject[0].toUpperCase()}${subject.substring(1)}';
    void open() => SignedImageDialog.show(
      context,
      fetchFile: () => fetchSignedFile(billId, kind),
      subject: subject,
      fileName: name == null ? title : '$title · $name',
      saveName: '$subject-${name ?? 'bill-$billId'}-$url'.replaceAll(_unsafe, '_'),
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
