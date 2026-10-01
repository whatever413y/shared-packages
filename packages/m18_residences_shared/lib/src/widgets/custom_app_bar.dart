import 'package:flutter/material.dart';

import 'logout_scope.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  /// Show a logout button instead of "back"; it runs the app's [LogoutScope] action.
  final bool logoutOnBack;
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
    this.showRefresh = false,
    this.onRefresh,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;

    final actionWidgets = [
      ...?actions,
      if (showRefresh)
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: onRefresh,
        ),
    ];

    return AppBar(
      centerTitle: centerTitle,
      title: _buildTitle(appBarTheme.titleTextStyle),
      backgroundColor: appBarTheme.backgroundColor,
      iconTheme: appBarTheme.iconTheme,
      actionsIconTheme: appBarTheme.actionsIconTheme ?? appBarTheme.iconTheme,
      elevation: appBarTheme.elevation ?? 4,
      actions: actionWidgets.isNotEmpty ? actionWidgets : null,
      leading: IconButton(
        icon: logoutOnBack ? const Icon(Icons.logout, color: Colors.white) : leading ?? const Icon(Icons.arrow_back, color: Colors.white),
        tooltip: logoutOnBack ? 'Logout' : 'Back',
        onPressed: () => logoutOnBack ? LogoutScope.logout(context) : Navigator.of(context).pop(true),
      ),
    );
  }

  Widget _buildTitle(TextStyle? titleStyle) {
    final align = centerTitle ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, textAlign: align, style: titleStyle),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: align,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
