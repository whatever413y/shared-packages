import 'package:flutter/material.dart';

import '../web/turnstile_view.dart';

/// The Cloudflare Turnstile site key, set at build time like `API_URL` (`TURNSTILE_SITE_KEY` in `.env`, or
/// `--dart-define=TURNSTILE_SITE_KEY=...`). Public: it only names the widget.
class TurnstileConfig {
  static const String _siteKey = String.fromEnvironment('TURNSTILE_SITE_KEY');

  static String get siteKey {
    if (_siteKey.isEmpty) {
      throw StateError(
        'TURNSTILE_SITE_KEY is not set. Run with --dart-define-from-file=.env (containing '
        'TURNSTILE_SITE_KEY=1x00000000000000000000AA, Cloudflare\'s always-pass test key) or --dart-define=TURNSTILE_SITE_KEY=<key>.',
      );
    }
    return _siteKey;
  }
}

/// The state of a [TurnstileField]: its current token (single use, so take one per login attempt) and whether the
/// widget failed to load.
class TurnstileController extends ChangeNotifier {
  String? _token;
  String? _error;
  VoidCallback? _resetWidget;

  /// The token Cloudflare issued, or `null` while the check runs, after it expired, or after [reset].
  String? get token => _token;

  /// Why the widget could not run (e.g. no connection), or `null`.
  String? get error => _error;

  /// Forgets the token and has the widget issue a new one: call it after every login attempt that used the token.
  void reset() {
    _token = null;
    _error = null;
    _resetWidget?.call();
    notifyListeners();
  }

  void _set({String? token, String? error}) {
    _token = token;
    _error = error;
    notifyListeners();
  }
}

/// Cloudflare Turnstile's "Verify you are human" box (always shown; usually checks by itself, sometimes asks for a
/// click), in the app's light or dark look. Its token lands in [controller]. Test id `turnstile`.
class TurnstileField extends StatelessWidget {
  final TurnstileController controller;

  /// What the token is for (`admin-login`, `tenant-login`), shown in Cloudflare's analytics.
  final String action;

  /// The widget's site key; [TurnstileConfig.siteKey] (the build's `TURNSTILE_SITE_KEY`) unless given.
  final String? siteKey;

  const TurnstileField({super.key, required this.controller, required this.action, this.siteKey});

  /// The widget's height in its flexible size (at least 300 px wide).
  static const double height = 65;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          identifier: 'turnstile',
          label: 'Human verification',
          child: SizedBox(
            height: height,
            child: TurnstileView(
              siteKey: siteKey ?? TurnstileConfig.siteKey,
              action: action,
              dark: theme.brightness == Brightness.dark,
              onToken: (token) => controller._set(token: token),
              onExpired: () => controller._set(),
              onError: (code) => controller._set(error: code),
              onReady: (reset) => controller._resetWidget = reset,
            ),
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.error == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "Verification couldn't load. Check your connection, then reload the page.",
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
        ),
      ],
    );
  }
}
