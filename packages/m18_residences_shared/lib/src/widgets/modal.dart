import 'package:flutter/material.dart';

import 'responsive.dart';
import 'selectable.dart';

/// Shows a modal built with [AppModal]: a bottom sheet on compact windows (phones), a centered dialog otherwise.
/// Either way its text can be selected and copied (its own [SelectionArea]). [dismissible]: a tap outside (or a
/// drag down on a sheet) closes it.
Future<T?> showAppModal<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  if (context.windowSize.isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      builder: (context) => _ModalKind(
        sheet: true,
        // Lifted above the on-screen keyboard, so the focused field and the actions stay visible.
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SelectionArea(child: builder(context)),
        ),
      ),
    );
  }
  return showSelectableDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    builder: (context) => _ModalKind(sheet: false, child: builder(context)),
  );
}

/// Whether the [AppModal] below is shown as a bottom sheet (set by [showAppModal]).
class _ModalKind extends InheritedWidget {
  final bool sheet;

  const _ModalKind({required this.sheet, required super.child});

  static bool isSheet(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_ModalKind>()?.sheet ?? false;

  @override
  bool updateShouldNotify(_ModalKind old) => old.sheet != sheet;
}

/// The content of every modal: a header (optional [leading] icon, [overline], [title], [subtitle], [trailing] and
/// a "Close" button), a scrolling body ([child]) and, with [actions], a footer that stays put while the body
/// scrolls: right-aligned in a dialog, sharing the width in a bottom sheet. Show it with [showAppModal].
///
/// Modals that only show something have no actions: the header's Close (the only button named "Close") closes them.
class AppModal extends StatelessWidget {
  final String title;
  final String? overline;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final List<Widget> actions;

  /// Widest the dialog gets (a sheet always spans the screen).
  final double maxWidth;

  const AppModal({
    super.key,
    required this.title,
    required this.child,
    this.overline,
    this.subtitle,
    this.leading,
    this.trailing,
    this.actions = const [],
    this.maxWidth = 560,
  });

  /// A tinted circle with [icon], for [leading] (e.g. a warning on a destructive confirmation).
  static Widget icon(BuildContext context, IconData icon, {Color? background, Color? foreground}) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 22,
      backgroundColor: background ?? scheme.primaryContainer,
      child: Icon(icon, color: foreground ?? scheme.onPrimaryContainer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _ModalKind.isSheet(context);
    final side = sheet ? 20.0 : 24.0;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: EdgeInsets.fromLTRB(side, sheet ? 0 : 20, 8, 12), child: _header(context)),
        Flexible(
          child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(side, 4, side, 20), child: child),
        ),
        if (actions.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: EdgeInsets.fromLTRB(side, 12, side, sheet ? 12 : 16),
            child: sheet
                ? Row(
                    children: [
                      for (final (i, action) in actions.indexed) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: action)],
                    ],
                  )
                : Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions),
          ),
        ],
      ],
    );
    if (sheet) return content;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[Padding(padding: const EdgeInsets.only(top: 4), child: leading!), const SizedBox(width: 14)],
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) ...[
                  Text(overline!, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                ],
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: theme.textTheme.bodySmall)],
              ],
            ),
          ),
        ),
        if (trailing != null) Padding(padding: const EdgeInsets.only(top: 8, left: 8), child: trailing!),
        IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).maybePop()),
      ],
    );
  }
}
