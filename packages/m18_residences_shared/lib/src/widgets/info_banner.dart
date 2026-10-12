import 'package:flutter/material.dart';

/// A short notice above a form, e.g. the login page's "Your session has ended. Please log in again.".
/// Announced to screen readers when it appears.
class InfoBanner extends StatelessWidget {
  final String message;
  final String? semanticsId;

  const InfoBanner(this.message, {super.key, this.semanticsId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      identifier: semanticsId,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer)),
            ),
          ],
        ),
      ),
    );
  }
}
