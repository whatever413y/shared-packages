import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Cloudflare's script, loaded once and only when a login page needs it.
const _scriptUrl = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';

@JS('turnstile')
external _Turnstile? get _turnstile;

/// The script's global `turnstile` (explicit rendering).
extension type _Turnstile._(JSObject _) implements JSObject {
  external JSString? render(web.HTMLElement container, JSObject options);
  external void reset(JSString widgetId);
  external void remove(JSString widgetId);
}

Future<void>? _loading;

/// Loads [_scriptUrl] once (again after a failure).
Future<void> _loadScript() {
  if (_turnstile != null) return Future.value();
  return _loading ??= () {
    final done = Completer<void>();
    final script = web.HTMLScriptElement()
      ..src = _scriptUrl
      ..async = true;
    script.onload = ((web.Event _) => done.complete()).toJS;
    script.onerror = ((web.Event _) {
      _loading = null;
      script.remove();
      done.completeError(StateError('Turnstile script failed to load'));
    }).toJS;
    web.document.head!.append(script);
    return done.future;
  }();
}

/// Turnstile rendered into a `<div>` platform view, in its flexible size (fills the width, at least 300 px; 65 px
/// high). Re-rendered when [dark] changes; removed with the widget.
class TurnstileView extends StatefulWidget {
  final String siteKey;
  final String action;
  final bool dark;
  final ValueChanged<String> onToken;
  final VoidCallback onExpired;

  /// Turnstile's error code, or why its script didn't load.
  final ValueChanged<String> onError;

  /// Hands over the function that resets the widget (for a new token).
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
  State<TurnstileView> createState() => _TurnstileViewState();
}

class _TurnstileViewState extends State<TurnstileView> {
  web.HTMLElement? _container;
  String? _widgetId;

  @override
  void didUpdateWidget(TurnstileView old) {
    super.didUpdateWidget(old);
    if (old.dark != widget.dark || old.siteKey != widget.siteKey) {
      _remove();
      _render();
    }
  }

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _remove() {
    final id = _widgetId;
    _widgetId = null;
    if (id != null) _turnstile?.remove(id.toJS);
  }

  Future<void> _render() async {
    final container = _container;
    if (container == null) return;
    try {
      await _loadScript();
    } catch (e) {
      if (mounted) widget.onError('$e');
      return;
    }
    // The platform view's element joins the page a frame after it is created.
    for (var i = 0; i < 100 && !container.isConnected; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final turnstile = _turnstile;
    if (!mounted || _container != container || _widgetId != null || turnstile == null) return;

    final options = JSObject()
      ..['sitekey'] = widget.siteKey.toJS
      ..['action'] = widget.action.toJS
      ..['theme'] = (widget.dark ? 'dark' : 'light').toJS
      ..['size'] = 'flexible'.toJS
      ..['callback'] = ((JSString token) => widget.onToken(token.toDart)).toJS
      ..['expired-callback'] = (() => widget.onExpired()).toJS
      ..['error-callback'] = ((JSAny? code) {
        widget.onError('$code');
        // Handled: Turnstile then doesn't throw the error into the console.
        return true.toJS;
      }).toJS;
    _widgetId = turnstile.render(container, options)?.toDart;
    widget.onReady(() {
      final id = _widgetId;
      if (id != null) _turnstile?.reset(id.toJS);
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'div',
    onElementCreated: (element) {
      _container = (element as web.HTMLElement)
        ..style.width = '100%'
        ..style.height = '100%';
      _render();
    },
  );
}
