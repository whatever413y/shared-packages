/// A zone suffix at the end of an ISO 8601 timestamp: `Z` or an offset like `+08:00`.
final _zone = RegExp(r'(Z|[+-]\d\d:?\d\d)$');

/// Parses a server timestamp in local time. The server sends UTC without a zone (`2026-09-25T06:59:41`),
/// which `DateTime.parse` would read as local time (8 h off in the Philippines).
DateTime parseServerTimestamp(String value) => DateTime.parse(_zone.hasMatch(value) ? value : '${value}Z').toLocal();
