import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Picked image, ready to be uploaded.
class UploadImage {
  const UploadImage({required this.path, required this.filename});

  final String path;
  final String filename;
}

http.MultipartFile multipartFile(String field, UploadImage image) {
  final file = File(image.path);
  return http.MultipartFile(
    field,
    file.openRead(),
    file.lengthSync(),
    filename: image.filename,
    contentType: _contentType(image.filename),
  );
}

MediaType _contentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  if (lower.endsWith('.gif')) return MediaType('image', 'gif');
  return MediaType('image', 'jpeg');
}
