import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'responsive.dart';

/// One top-level screen of an [AdaptiveScaffold].
class AdaptiveDestination {
  final String label;

  /// A shorter label for the bottom bar on phones (defaults to [label]).
  final String compactLabel;
  final IconData icon;
  final IconData selectedIcon;

  /// Shown as a badge on the icon when above zero (e.g. payments waiting for verification).
  final int badgeCount;

  const AdaptiveDestination({required this.label, required this.icon, IconData? selectedIcon, this.badgeCount = 0, String? compactLabel})
    : selectedIcon = selectedIcon ?? icon,
      compactLabel = compactLabel ?? label;

  Widget _icon(bool selected) {
    final child = Icon(selected ? selectedIcon : icon);
    if (badgeCount <= 0) return child;
    return Badge(label: Text('$badgeCount'), child: child);
  }
}

/// App navigation that adapts to the window: a bottom [NavigationBar] on compact windows (with a "More" sheet when
/// there are more than [compactLimit] destinations), a [NavigationRail] on medium ones and an extended rail with
/// labels on expanded ones. [body] is the selected destination's page (typically an `IndexedStack`).
class AdaptiveScaffold extends StatelessWidget {
  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Above the rail (e.g. the brand); `extended` is true on expanded windows.
  final Widget Function(BuildContext context, bool extended)? railHeader;

  /// At the bottom of the rail (e.g. a logout button).
  final Widget Function(BuildContext context, bool extended)? railFooter;

  /// The most items the bottom bar shows; with more destinations, its last item is "More".
  final int compactLimit;

  /// Extra entries at the end of the "More" sheet (e.g. a logout tile).
  final List<Widget> Function(BuildContext sheetContext)? moreSheetFooter;

  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.railHeader,
    this.railFooter,
    this.compactLimit = 5,
    this.moreSheetFooter,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.windowSize;
    if (size.isCompact) return _compact(context);
    return _withRail(context, extended: size.isExpanded);
  }

  Widget _withRail(BuildContext context, {required bool extended}) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.panelColor(scheme),
              border: Border(right: BorderSide(color: scheme.outlineVariant)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (railHeader != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(extended ? 20 : 0, 16, extended ? 20 : 0, 8),
                      child: SizedBox(
                        width: extended ? 216 : 80,
                        child: Align(alignment: extended ? Alignment.centerLeft : Alignment.center, child: railHeader!(context, extended)),
                      ),
                    ),
                  Expanded(
                    child: NavigationRail(
                      extended: extended,
                      minExtendedWidth: 256,
                      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      destinations: [
                        for (final d in destinations)
                          NavigationRailDestination(icon: d._icon(false), selectedIcon: d._icon(true), label: Text(d.label)),
                      ],
                    ),
                  ),
                  if (railFooter != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: SizedBox(width: extended ? 232 : 56, child: railFooter!(context, extended)),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _compact(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overflow = destinations.length > compactLimit;
    final inBar = overflow ? destinations.take(compactLimit - 1).toList() : destinations;
    final barIndex = overflow && selectedIndex >= inBar.length ? inBar.length : selectedIndex;
    final moreBadge = overflow ? destinations.skip(inBar.length).fold(0, (sum, d) => sum + d.badgeCount) : 0;

    return Scaffold(
      body: body,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        // Five labels share a phone's width: larger system text grows them a little, never onto a second line.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: NavigationBar(
            selectedIndex: barIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) => index < inBar.length ? onDestinationSelected(index) : _showMore(context, inBar.length),
            destinations: [
              for (final d in inBar)
                NavigationDestination(icon: d._icon(false), selectedIcon: d._icon(true), label: d.compactLabel, tooltip: d.label),
              if (overflow)
                NavigationDestination(
                  icon: AdaptiveDestination(label: 'More', icon: Icons.menu, badgeCount: moreBadge)._icon(false),
                  label: 'More',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context, int first) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = first; i < destinations.length; i++)
                Semantics(
                  button: true,
                  child: ListTile(
                    leading: destinations[i]._icon(i == selectedIndex),
                    title: Text(destinations[i].label),
                    selected: i == selectedIndex,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDestinationSelected(i);
                    },
                  ),
                ),
              if (moreSheetFooter != null) ...[const Divider(height: 16), ...moreSheetFooter!(sheetContext)],
            ],
          ),
        ),
      ),
    );
  }
}
