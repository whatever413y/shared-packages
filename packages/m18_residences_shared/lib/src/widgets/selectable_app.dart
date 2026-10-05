import 'package:flutter/material.dart';

/// Makes every text below it selectable and copyable (mouse drag, or long press on phones), dialogs included.
/// Use it as `MaterialApp(builder: (context, child) => SelectableApp(child: child!))`.
class SelectableApp extends StatefulWidget {
  final Widget child;

  const SelectableApp({super.key, required this.child});

  @override
  State<SelectableApp> createState() => _SelectableAppState();
}

class _SelectableAppState extends State<SelectableApp> {
  // The selection handles and context menu need an Overlay above the SelectionArea, which sits above the
  // app's Navigator (and its Overlay) here. The entry lives as long as the app.
  late final OverlayEntry _entry = OverlayEntry(builder: (_) => SelectionArea(child: widget.child));

  @override
  void didUpdateWidget(SelectableApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) _entry.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
