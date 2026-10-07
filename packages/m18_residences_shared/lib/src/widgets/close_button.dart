import 'package:flutter/material.dart';

/// The close button of modals, toasts and the image viewer: a soft filled circle of [size] with a thin X that
/// darkens on hover and shows a ring on keyboard focus. The tap target is at least 48 px. [tooltip] is also its
/// accessible name ("Close"; toasts use "Dismiss").
class CloseCircleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final String tooltip;

  const CloseCircleButton({super.key, required this.onPressed, this.size = 36, this.tooltip = 'Close'});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = scheme.surfaceContainerHighest;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(Size.square(size)),
        minimumSize: WidgetStatePropertyAll(Size.square(size)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: const WidgetStatePropertyAll(CircleBorder()),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)
              ? Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.10), fill)
              : fill,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered) ? scheme.onSurface : scheme.onSurfaceVariant,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused) ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
        ),
      ),
      icon: _ThinCross(size: size * 0.38),
    );
  }
}

/// An X drawn with a thin round stroke in the icon color (the icon font's X is heavier).
class _ThinCross extends StatelessWidget {
  final double size;

  const _ThinCross({required this.size});

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return CustomPaint(size: Size.square(size), painter: _CrossPainter(color));
  }
}

class _CrossPainter extends CustomPainter {
  final Color color;

  _CrossPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}
