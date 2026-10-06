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

/// The apps' logo: the roofline M (two house gables) on a rounded tile in the theme's primary color, optionally
/// followed by [label]. The same mark as the apps' web icons (`web/icons/logo.svg`).
class BrandMark extends StatelessWidget {
  final String? label;
  final double size;

  const BrandMark({super.key, this.label, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tile = Semantics(
      label: 'M18 Residences logo',
      child: CustomPaint(size: Size.square(size), painter: _RooflineMPainter(scheme.primary, scheme.onPrimary)),
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

/// The logo on a 512 grid (as in the web icons): a tile with radius 112 and the gables
/// `M128 350 V226 L192 162 L256 226 L320 162 L384 226 V350`, stroked 44 wide with round ends.
class _RooflineMPainter extends CustomPainter {
  final Color background;
  final Color foreground;

  const _RooflineMPainter(this.background, this.foreground);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 512;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & Size.square(512 * k), Radius.circular(112 * k)), Paint()..color = background);
    final mark = Path()
      ..moveTo(128 * k, 350 * k)
      ..lineTo(128 * k, 226 * k)
      ..lineTo(192 * k, 162 * k)
      ..lineTo(256 * k, 226 * k)
      ..lineTo(320 * k, 162 * k)
      ..lineTo(384 * k, 226 * k)
      ..lineTo(384 * k, 350 * k);
    canvas.drawPath(
      mark,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 44 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RooflineMPainter old) => old.background != background || old.foreground != foreground;
}
