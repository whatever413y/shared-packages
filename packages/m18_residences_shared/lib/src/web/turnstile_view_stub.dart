import 'package:flutter/widgets.dart';

/// Outside a browser (tests) there is no Turnstile: an empty box of the widget's size that never issues a token.
class TurnstileView extends StatelessWidget {
  final String siteKey;
  final String action;
  final bool dark;
  final ValueChanged<String> onToken;
  final VoidCallback onExpired;
  final ValueChanged<String> onError;
  final ValueChanged<VoidCallback> onReady;

  const TurnstileView({
    super.key,
    required this.siteKey,
    required this.action,
    required this.dark,
    required this.onToken,
    required this.onExpired,
    required this.onError,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
