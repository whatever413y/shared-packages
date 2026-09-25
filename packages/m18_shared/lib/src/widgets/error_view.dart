import 'package:flutter/material.dart';

import 'logout_scope.dart';

/// Centered error message with a "Refresh" button: runs [onRetry], or logs out via [LogoutScope] when there is nothing to retry.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: onRetry ?? () => LogoutScope.logout(context), icon: const Icon(Icons.refresh), label: const Text('Refresh')),
        ],
      ),
    );
  }
}
