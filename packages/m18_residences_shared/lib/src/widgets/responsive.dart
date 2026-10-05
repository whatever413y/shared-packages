import 'package:flutter/widgets.dart';

/// Width classes shared by both apps (Material 3 window size classes).
enum WindowSize {
  /// Phones: one column, drawer or bottom navigation, full-width dialogs.
  compact,

  /// Small tablets / narrow windows: two columns or a navigation rail.
  medium,

  /// Desktops: side navigation, multi-column grids, capped content width.
  expanded;

  /// Lower bound of [medium], in logical pixels.
  static const double mediumMin = 600;

  /// Lower bound of [expanded], in logical pixels.
  static const double expandedMin = 1024;

  /// Widest the main content gets on [expanded] screens.
  static const double maxContentWidth = 1200;

  static WindowSize fromWidth(double width) {
    if (width >= expandedMin) return expanded;
    if (width >= mediumMin) return medium;
    return compact;
  }

  bool get isCompact => this == compact;
  bool get isExpanded => this == expanded;
}

extension WindowSizeContext on BuildContext {
  /// The window's size class; rebuilds only when the window width changes.
  WindowSize get windowSize => WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}

/// Builds [compact], [medium] or [expanded] for the width its parent gives it
/// (not the window), so it also works inside panes and dialogs.
/// [medium] falls back to [compact], [expanded] to [medium].
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.compact, this.medium, this.expanded});

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediumOrCompact = medium ?? compact;
        return switch (WindowSize.fromWidth(constraints.maxWidth)) {
          WindowSize.compact => compact(context),
          WindowSize.medium => mediumOrCompact(context),
          WindowSize.expanded => (expanded ?? mediumOrCompact)(context),
        };
      },
    );
  }
}

/// Centers [child] and caps its width at [maxWidth] so pages don't stretch
/// across wide desktops.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = WindowSize.maxContentWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
