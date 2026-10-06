import 'package:flutter/material.dart';

import 'logout_scope.dart';

/// The apps' top bar: a title (and optional subtitle), a "Back" or "Logout" button, and a "Refresh" action.
/// Colors come from the theme's [AppBarTheme].
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  /// Show a logout button instead of "back"; it runs the app's [LogoutScope] action.
  final bool logoutOnBack;

  /// Show the leading "Back"/"Logout" button at all; off for pages inside a navigation shell.
  final bool showLeading;
  final bool showRefresh;
  final VoidCallback? onRefresh;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.logoutOnBack = false,
    this.showLeading = true,
    this.showRefresh = false,
    this.onRefresh,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final actionWidgets = [
      ...?actions,
      if (showRefresh) IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: onRefresh),
      const SizedBox(width: 8),
    ];

    return AppBar(
      centerTitle: centerTitle,
      title: _buildTitle(context),
      automaticallyImplyLeading: false,
      actions: actionWidgets,
      leading: showLeading
          ? IconButton(
              icon: logoutOnBack ? const Icon(Icons.logout) : leading ?? const Icon(Icons.arrow_back),
              tooltip: logoutOnBack ? 'Logout' : 'Back',
              onPressed: () => logoutOnBack ? LogoutScope.logout(context) : Navigator.of(context).pop(true),
            )
          : null,
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final align = centerTitle ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, textAlign: align),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: align,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
