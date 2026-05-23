import 'dart:convert';

import 'package:http/http.dart' as http;

Map<String, dynamic> decodeApiResponse(
  http.Response response, {
  String fallbackMessage = 'Request failed',
}) {
  final body = response.body.trim();
  if (body.isEmpty) {
    if (response.statusCode == 413) {
      throw Exception(
        'Upload failed because the selected image is too large. Please choose a smaller photo.',
      );
    }

    throw Exception(
      '$fallbackMessage. Empty server response (${response.statusCode}).',
    );
  }

  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } on FormatException {
    final message = _messageForNonJsonResponse(response, fallbackMessage);
    throw Exception(message);
  }

  throw Exception(
    '$fallbackMessage. Invalid server response (${response.statusCode}).',
  );
}

String _messageForNonJsonResponse(
  http.Response response,
  String fallbackMessage,
) {
  if (response.statusCode == 413) {
    return 'Upload failed because the selected image is too large. Please choose a smaller photo.';
  }

  final body = response.body.trimLeft().toLowerCase();
  if (body.startsWith('<html') || body.startsWith('<!doctype html')) {
    return '$fallbackMessage. The server returned an HTML error page (${response.statusCode}). The selected image may be too large.';
  }

  return '$fallbackMessage. The server returned an invalid response (${response.statusCode}).';
}
