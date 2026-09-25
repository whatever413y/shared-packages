import 'package:flutter/widgets.dart';

/// Supplies the app's logout action to shared widgets (the app bar's logout button, [ErrorView]'s fallback).
///
/// Wrap the app's `MaterialApp` in it so every route can reach it:
/// `LogoutScope(onLogout: (context) { ...dispatch logout, go to login... }, child: MaterialApp(...))`.
class LogoutScope extends InheritedWidget {
  final void Function(BuildContext context) onLogout;

  const LogoutScope({super.key, required this.onLogout, required super.child});

  /// Runs the app's logout action; throws if no [LogoutScope] is above [context].
  static void logout(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LogoutScope>();
    if (scope == null) {
      throw FlutterError('LogoutScope.logout() called with no LogoutScope above this widget. Wrap the MaterialApp in a LogoutScope.');
    }
    scope.onLogout(context);
  }

  @override
  bool updateShouldNotify(LogoutScope oldWidget) => onLogout != oldWidget.onLogout;
}
