/// A short-lived link to a stored file (a receipt or a payment image) and its type.
class SignedFile {
  final String url;

  /// The stored file's MIME type, e.g. `image/webp` or `application/pdf`; `null` if unknown.
  final String? contentType;

  const SignedFile({required this.url, this.contentType});

  /// PDFs open in a new browser tab; everything else is shown as an image.
  bool get isPdf => contentType == 'application/pdf';

  factory SignedFile.fromJson(Map<String, dynamic> json) => SignedFile(url: json['url'] as String, contentType: json['content_type'] as String?);
}
