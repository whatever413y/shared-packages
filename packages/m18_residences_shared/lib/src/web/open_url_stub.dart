/// Opens [url] in a new browser tab. Outside a browser (tests) there is nothing to open.
void openInNewTab(String url) => throw UnsupportedError('Opening $url needs a browser');
