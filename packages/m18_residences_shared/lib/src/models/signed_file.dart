/// A short-lived link to a stored file (a receipt or a payment image) and its type.
class SignedFile {
  final String url;

  /// The stored file's MIME type, e.g. `image/webp` or `application/pdf`; `null` if unknown.
  final String? contentType;

  const SignedFile({required this.url, this.contentType});

  /// PDFs open in a new browser tab; everything else is shown as an image.
  bool get isPdf => contentType == 'application/pdf';

  /// Image types a saved copy is converted from to JPEG (not every phone or gallery opens them).
  static const _savedAsJpeg = {'image/webp', 'image/avif', 'image/gif'};

  /// Whether saving converts the file to JPEG.
  bool get savesAsJpeg => _savedAsJpeg.contains(contentType);

  /// The file extension of a saved copy.
  String get saveExtension => savesAsJpeg
      ? 'jpg'
      : switch (contentType) {
          'image/jpeg' => 'jpg',
          'image/png' => 'png',
          'application/pdf' => 'pdf',
          _ => 'bin',
        };

  factory SignedFile.fromJson(Map<String, dynamic> json) => SignedFile(url: json['url'] as String, contentType: json['content_type'] as String?);
}
