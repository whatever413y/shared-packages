import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'close_button.dart';
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
      // AppModal draws the handle inside its header band.
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
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

/// The content of every modal: a tinted header band (optional [leading] icon tile, [overline], [title], [subtitle],
/// [trailing] and the round Close button), a scrolling body ([child], often [AppModalSection]s) and, with [actions],
/// a footer strip that stays put while the body scrolls: right-aligned in a dialog, sharing the width in a bottom
/// sheet. Show it with [showAppModal].
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

  /// The header band's tint (the primary color by default; e.g. the error color for a destructive confirmation).
  final Color? tint;

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
    this.tint,
    this.maxWidth = 560,
  });

  /// A rounded tile with [icon], for [leading] (e.g. a trash can on a destructive confirmation).
  static Widget icon(BuildContext context, IconData icon, {Color? background, Color? foreground}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background ?? scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 22, color: foreground ?? scheme.onPrimaryContainer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _ModalKind.isSheet(context);
    final scheme = Theme.of(context).colorScheme;
    final side = sheet ? 20.0 : 24.0;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.modalBandColor(scheme, tint),
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sheet)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: scheme.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              Padding(padding: EdgeInsets.fromLTRB(side, sheet ? 10 : 18, 12, 16), child: _header(context)),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(side, 20, side, 24), child: child),
        ),
        if (actions.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.footerColor(scheme),
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, 12, side, sheet ? 12 : 14),
              child: sheet
                  ? Row(
                      children: [
                        for (final (i, action) in actions.indexed) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: action)],
                      ],
                    )
                  : Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions),
            ),
          ),
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
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[Padding(padding: const EdgeInsets.only(top: 2), child: leading!), const SizedBox(width: 14)],
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: leading == null ? 6 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) ...[
                  Text(
                    overline!,
                    style: theme.textTheme.labelMedium?.copyWith(color: tint ?? scheme.primary, fontWeight: FontWeight.w600, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ),
        if (trailing != null) Padding(padding: const EdgeInsets.only(top: 8, left: 8), child: trailing!),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CloseCircleButton(onPressed: () => Navigator.of(context).maybePop()),
        ),
      ],
    );
  }
}

/// A labeled group in a modal's body: [label] (with an optional [trailing] widget, e.g. an add button) above a soft
/// panel holding [child].
class AppModalSection extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppModalSection({super.key, required this.label, required this.child, this.trailing, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              ?trailing,
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.softPanelColor(scheme),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}
