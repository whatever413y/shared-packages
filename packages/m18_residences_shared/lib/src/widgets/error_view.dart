import 'package:flutter/material.dart';

import 'logout_scope.dart';

/// Centered error message with a "Refresh" button: runs [onRetry], or logs out via [LogoutScope] when there is nothing to retry.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.errorContainer,
                child: Icon(Icons.cloud_off_outlined, color: scheme.onErrorContainer),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry ?? () => LogoutScope.logout(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
