import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class ImageUploadUtils {
  static const double maxImageDimension = 800;
  static const int imageQuality = 65;

  // Base64 adds about 33%, so 5 MB raw image data stays under the API's 7 MB JSON limit.
  static const int maxImageBytes = 5 * 1024 * 1024;

  static Future<String> toDataUrl(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.lengthInBytes > maxImageBytes) {
      throw Exception(
        'Selected image is too large (${_formatBytes(bytes.lengthInBytes)}). Please choose a smaller photo.',
      );
    }

    return 'data:${_mimeTypeFor(image)};base64,${base64Encode(bytes)}';
  }

  static String _mimeTypeFor(XFile image) {
    final mimeType = image.mimeType?.toLowerCase();
    if (mimeType != null && mimeType.startsWith('image/')) {
      return mimeType == 'image/jpg' ? 'image/jpeg' : mimeType;
    }

    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.heic')) return 'image/heic';
    if (name.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  static String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(bytes / 1024).round()} KB';
  }
}
