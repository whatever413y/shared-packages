import 'package:flutter/widgets.dart';

/// Outside a browser (tests) there is no Turnstile: an empty box of the widget's size that never issues a token.
class TurnstileView extends StatelessWidget {
  final String siteKey;
  final String action;
  final bool dark;

  /// Turnstile's compact size (150 × 140) instead of the flexible one.
  final bool compact;
  final ValueChanged<String> onToken;
  final VoidCallback onExpired;
  final ValueChanged<String> onError;
  final ValueChanged<VoidCallback> onReady;

  const TurnstileView({
    super.key,
    required this.siteKey,
    required this.action,
    required this.dark,
    required this.compact,
    required this.onToken,
    required this.onExpired,
    required this.onError,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
