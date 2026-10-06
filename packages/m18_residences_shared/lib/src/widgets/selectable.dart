import 'package:flutter/material.dart';

/// Gives every page its own [SelectionArea] (with the platform's usual transition), so its text can be selected
/// and copied. One area per route: a single area around the whole Navigator also picks up the text of the hidden
/// pages underneath, which then gets selected instead. [AppTheme] uses it for every platform.
class SelectablePageTransitionsBuilder extends PageTransitionsBuilder {
  const SelectablePageTransitionsBuilder();

  static const _defaults = PageTransitionsTheme();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _defaults.buildTransitions(route, context, animation, secondaryAnimation, SelectionArea(child: child));
}

/// [showDialog] with the dialog in its own [SelectionArea], so its text can be selected and copied.
Future<T?> showSelectableDialog<T>({required BuildContext context, required WidgetBuilder builder, bool barrierDismissible = true}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: (context) => SelectionArea(child: builder(context)),
);

/// A page kept alive next to others (e.g. in an [IndexedStack] of a navigation shell) with its own [SelectionArea],
/// cut off from the route's: otherwise the hidden pages' text shares the route's area and a drag over the visible
/// page can select text of a hidden one.
class SelectablePage extends StatelessWidget {
  final Widget child;

  const SelectablePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) => SelectionContainer.disabled(child: SelectionArea(child: child));
}
