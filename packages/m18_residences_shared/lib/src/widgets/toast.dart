import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'responsive.dart';

enum ToastType { success, error, info, loading }

/// Short messages about what just happened ("Bill created", "Uploading the GCash QR code...", errors), as a card
/// at the top: top-right on wider windows, across the top on phones, so they never cover a bottom bar or a
/// floating button. One at a time: a new toast replaces the current one (a "...ing" toast is replaced by its
/// result). Success and info toasts close after [autoClose] (paused while the pointer is over them), loading ones
/// when replaced, errors only when dismissed. Screen readers announce them.
class AppToast {
  AppToast._();

  static const Duration autoClose = Duration(seconds: 4);

  /// Longest a loading toast stays when nothing replaces it.
  static const Duration loadingLimit = Duration(seconds: 30);

  static OverlayEntry? _entry;
  static GlobalKey<_ToastCardState>? _card;

  static void show(BuildContext context, String message, {ToastType type = ToastType.info, String? title}) {
    _removeNow();
    final overlay = Overlay.of(context, rootOverlay: true);
    final card = GlobalKey<_ToastCardState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastPosition(
        child: _ToastCard(
          key: card,
          message: message,
          title: title,
          type: type,
          onClosed: () {
            if (identical(_entry, entry)) _removeNow();
          },
        ),
      ),
    );
    _entry = entry;
    _card = card;
    overlay.insert(entry);
  }

  /// Closes the current toast (with its exit animation), if any.
  static void hide() {
    final state = _card?.currentState;
    if (state == null) {
      _removeNow();
    } else {
      state.close();
    }
  }

  static void _removeNow() {
    final entry = _entry;
    _entry = null;
    _card = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

/// Top-right (360 px wide) on wider windows, across the top on phones; below the system's top inset.
class _ToastPosition extends StatelessWidget {
  final Widget child;

  const _ToastPosition({required this.child});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    if (context.windowSize.isCompact) {
      return Positioned(top: top + 12, left: 12, right: 12, child: child);
    }
    return Positioned(top: top + 16, right: 16, width: 380, child: child);
  }
}

class _ToastCard extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final VoidCallback onClosed;

  const _ToastCard({super.key, required this.message, required this.title, required this.type, required this.onClosed});

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  late final AnimationController _shown = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..forward();

  /// Runs from 0 to 1 while an auto-closing toast is up (drawn as the line along its bottom).
  late final AnimationController _life = AnimationController(vsync: this, duration: AppToast.autoClose);
  Timer? _loadingLimit;
  bool _closing = false;

  bool get _autoCloses => widget.type == ToastType.success || widget.type == ToastType.info;

  @override
  void initState() {
    super.initState();
    if (_autoCloses) {
      // A status listener, not the forward() future: that one never completes once a hover has stopped it.
      _life.addStatusListener((status) {
        if (status == AnimationStatus.completed) close();
      });
      _life.forward();
    } else if (widget.type == ToastType.loading) {
      _loadingLimit = Timer(AppToast.loadingLimit, close);
    }
  }

  @override
  void dispose() {
    _loadingLimit?.cancel();
    _life.dispose();
    _shown.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _life.stop();
    await _shown.reverse();
    widget.onClosed();
  }

  (Color, Color, Widget) _style(ThemeData theme) {
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    return switch (widget.type) {
      ToastType.success => (status.paid, status.onPaid, Icon(Icons.check_circle, color: status.onPaid, size: 20)),
      ToastType.error => (scheme.errorContainer, scheme.onErrorContainer, Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20)),
      ToastType.info => (scheme.primaryContainer, scheme.onPrimaryContainer, Icon(Icons.info_outline, color: scheme.onPrimaryContainer, size: 20)),
      ToastType.loading => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimaryContainer)),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (badge, accent, icon) = _style(theme);
    final curve = CurvedAnimation(parent: _shown, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    final card = Material(
      color: AppTheme.panelColor(scheme),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: badge, child: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null) Text(widget.title!, style: theme.textTheme.titleSmall),
                      Text(
                        widget.message,
                        style: widget.title == null ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500) : theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Dismiss', icon: const Icon(Icons.close, size: 18), onPressed: close),
              ],
            ),
          ),
          if (_autoCloses)
            AnimatedBuilder(
              animation: _life,
              builder: (context, _) => LinearProgressIndicator(
                value: 1 - _life.value,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                color: accent.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -0.3), end: Offset.zero).animate(curve),
        child: Semantics(
          container: true,
          liveRegion: true,
          // Pausing on hover lets a long message be read before it closes.
          child: MouseRegion(
            onEnter: (_) => _life.stop(),
            onExit: (_) {
              if (_autoCloses && !_closing) _life.forward();
            },
            child: card,
          ),
        ),
      ),
    );
  }
}
