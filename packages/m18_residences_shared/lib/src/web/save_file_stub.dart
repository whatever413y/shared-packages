import '../models/signed_file.dart';

/// Saves [file] as a download. Outside a browser (tests) there is nothing to save to.
Future<void> saveSignedFile(SignedFile file, String baseName) async => throw UnsupportedError('Saving ${file.url} needs a browser');
