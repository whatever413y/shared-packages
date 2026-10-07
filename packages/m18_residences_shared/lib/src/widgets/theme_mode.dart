import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'toast.dart';

/// The app's light/dark choice: [ThemeMode.system] (the default) follows the device; a manual switch is saved in
/// this browser (`theme_mode` in shared_preferences; logging out keeps it). Give it to `MaterialApp.themeMode`
/// through a [ThemeModeScope].
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController([super.value = ThemeMode.system]);

  static const String prefsKey = 'theme_mode';

  /// The saved choice, or [ThemeMode.system].
  static Future<ThemeModeController> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(prefsKey);
    return ThemeModeController(switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    });
  }

  /// Applies [mode] at once, then saves it ([ThemeMode.system] forgets the choice); throws if the browser refused.
  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    final saved = mode == ThemeMode.system ? await prefs.remove(prefsKey) : await prefs.setString(prefsKey, mode.name);
    if (!saved) throw StateError('Could not save the theme in this browser');
  }

  /// Switches to the other look than [shown]. When that is what the device asks for ([platform]), the app goes back
  /// to following the device.
  Future<void> toggle({required Brightness shown, required Brightness platform}) {
    final target = shown == Brightness.dark ? Brightness.light : Brightness.dark;
    if (target == platform) return setMode(ThemeMode.system);
    return setMode(target == Brightness.dark ? ThemeMode.dark : ThemeMode.light);
  }
}

/// Makes a [ThemeModeController] available below it (wrap `MaterialApp`, and build its `themeMode` from
/// [ThemeModeScope.of]); dependents rebuild when the mode changes.
class ThemeModeScope extends InheritedNotifier<ThemeModeController> {
  const ThemeModeScope({super.key, required ThemeModeController controller, required super.child}) : super(notifier: controller);

  static ThemeModeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    if (scope == null) throw FlutterError('ThemeModeScope.of() called without a ThemeModeScope above it (wrap MaterialApp in one).');
    return scope.notifier!;
  }
}

/// Toggles the shown theme ([context]'s brightness against the device's), reporting a failed save with a toast.
Future<void> _toggle(BuildContext context) async {
  final controller = ThemeModeScope.of(context);
  try {
    await controller.toggle(shown: Theme.of(context).brightness, platform: MediaQuery.platformBrightnessOf(context));
  } catch (e) {
    if (context.mounted) AppToast.show(context, "The theme can't be remembered in this browser.", type: ToastType.error);
  }
}

/// A sun/moon button that switches between light and dark (test id `theme-toggle`).
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeModeScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      identifier: 'theme-toggle',
      child: IconButton(
        tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
        onPressed: () => _toggle(context),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween(begin: 0.75, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, key: ValueKey(dark)),
        ),
      ),
    );
  }
}

/// The light/dark switch as a list row ("Dark mode"), for menus such as the phone "More" sheet.
class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeModeScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      identifier: 'theme-toggle',
      child: SwitchListTile(
        secondary: Icon(dark ? Icons.dark_mode : Icons.dark_mode_outlined),
        title: const Text('Dark mode'),
        value: dark,
        onChanged: (_) => _toggle(context),
      ),
    );
  }
}
