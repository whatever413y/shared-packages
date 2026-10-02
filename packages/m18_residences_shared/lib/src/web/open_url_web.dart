import 'package:web/web.dart' as web;

/// Opens [url] in a new browser tab (call it from a user gesture, or popup blockers refuse it).
void openInNewTab(String url) => web.window.open(url, '_blank', 'noopener');
