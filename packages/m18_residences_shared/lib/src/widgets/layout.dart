import 'package:flutter/material.dart';

/// A section heading: [title] (and an optional [subtitle]) with an optional [trailing] action on the same line.
class AppSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSection({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: theme.textTheme.bodySmall)],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// A friendly "nothing here" message: an icon in a tinted circle, a [title], an optional [message] and [action].
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, size: 28, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// The apps' brand mark: a rounded teal tile with "M18", optionally followed by [label].
class BrandMark extends StatelessWidget {
  final String? label;
  final double size;

  const BrandMark({super.key, this.label, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Text(
        'M18',
        style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: size * 0.34, letterSpacing: -0.3),
      ),
    );
    if (label == null) return tile;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        const SizedBox(width: 10),
        Flexible(
          child: Text(label!, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }
}
