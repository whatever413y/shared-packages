import 'package:flutter/widgets.dart';

/// Width classes shared by both apps (Material 3 window size classes).
enum WindowSize {
  /// Phones: one column, drawer or bottom navigation, full-width dialogs.
  compact,

  /// Small tablets / narrow windows: two columns or a navigation rail.
  medium,

  /// Desktops: side navigation, multi-column grids, content capped at [maxContentWidth].
  expanded,

  /// Large desktops (1920, 2560 px wide screens): like [expanded], with content up to [largeContentWidth].
  large;

  /// Lower bound of [medium], in logical pixels.
  static const double mediumMin = 600;

  /// Lower bound of [expanded], in logical pixels.
  static const double expandedMin = 1024;

  /// Lower bound of [large], in logical pixels.
  static const double largeMin = 1600;

  /// Widest the main content gets on [expanded] screens.
  static const double maxContentWidth = 1200;

  /// Widest the main content gets on [large] screens.
  static const double largeContentWidth = 1600;

  static WindowSize fromWidth(double width) {
    if (width >= largeMin) return large;
    if (width >= expandedMin) return expanded;
    if (width >= mediumMin) return medium;
    return compact;
  }

  bool get isCompact => this == compact;

  /// [expanded] or [large]: side navigation with labels.
  bool get isExpanded => this == expanded || this == large;
  bool get isLarge => this == large;

  /// Widest the main content gets in a window of this size.
  double get contentMaxWidth => isLarge ? largeContentWidth : maxContentWidth;
}

extension WindowSizeContext on BuildContext {
  /// The window's size class; rebuilds only when the window width changes.
  WindowSize get windowSize => WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}

/// Builds [compact], [medium] or [expanded] for the width its parent gives it
/// (not the window), so it also works inside panes and dialogs.
/// [medium] falls back to [compact], [expanded] to [medium]; large widths use [expanded].
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
          WindowSize.expanded || WindowSize.large => (expanded ?? mediumOrCompact)(context),
        };
      },
    );
  }
}

/// Centers [child] and caps its width so pages don't stretch across wide desktops: at [maxWidth], or by default at
/// the window's [WindowSize.contentMaxWidth] (1200 px, 1600 px on large screens).
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? context.windowSize.contentMaxWidth),
        child: child,
      ),
    );
  }
}
