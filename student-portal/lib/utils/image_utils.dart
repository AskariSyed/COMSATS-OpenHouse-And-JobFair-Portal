import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Maximum file size allowed: 1MB
const int MAX_FILE_SIZE_BYTES = 1048576; // 1MB

/// Image quality for compression (0-100)
const int QUALITY_HIGH = 85;
const int QUALITY_MEDIUM = 75;
const int QUALITY_LOW = 65;

class ImageUtils {
  /// Check if file size exceeds the maximum allowed size
  static bool isFileTooLarge(int fileSizeBytes) {
    return fileSizeBytes > MAX_FILE_SIZE_BYTES;
  }

  /// Get human-readable file size
  static String getFileSizeDisplay(int fileSizeBytes) {
    if (fileSizeBytes < 1024) return "$fileSizeBytes B";
    if (fileSizeBytes < 1024 * 1024)
      return "${(fileSizeBytes / 1024).toStringAsFixed(2)} KB";
    return "${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  /// Get maximum file size in MB display
  static String getMaxFileSizeDisplay() {
    return "${(MAX_FILE_SIZE_BYTES / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  /// Resize image to a smaller size while maintaining aspect ratio
  /// Returns the resized image as bytes
  static Future<Uint8List> resizeImage(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = QUALITY_HIGH,
  }) async {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception("Failed to decode image");

      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;

      if (image.width > maxWidth || image.height > maxHeight) {
        final aspectRatio = image.width / image.height;
        if (aspectRatio > 1) {
          // Landscape
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).toInt();
        } else {
          // Portrait
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).toInt();
        }
      }

      // Resize the image
      final resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode as JPEG with specified quality
      final encoded = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(encoded);
    } catch (e) {
      debugPrint("❌ Error resizing image: $e");
      rethrow;
    }
  }

  /// Compress image aggressively for size reduction
  /// Returns the compressed image as bytes
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 600,
    int maxHeight = 600,
  }) async {
    try {
      // First resize
      final resized = await resizeImage(
        imageBytes,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: QUALITY_MEDIUM,
      );

      // If still too large, compress more
      if (resized.length > MAX_FILE_SIZE_BYTES) {
        return await resizeImage(
          resized,
          maxWidth: 400,
          maxHeight: 400,
          quality: QUALITY_LOW,
        );
      }

      return resized;
    } catch (e) {
      debugPrint("❌ Error compressing image: $e");
      rethrow;
    }
  }

  /// Check if image is valid and get its size in bytes
  static Future<int?> getImageFileSizeBytes(XFile xFile) async {
    try {
      final file = File(xFile.path);
      return await file.length();
    } catch (e) {
      debugPrint("❌ Error getting file size: $e");
      return null;
    }
  }

  /// Crop image with user interaction
  /// Returns the cropped image file or null if cancelled
  static Future<XFile?> cropImage(XFile xFile) async {
    try {
      final imageBytes = await xFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Center-crop to a square so profile pictures stay consistent.
      final cropSize = image.width < image.height ? image.width : image.height;
      final offsetX = (image.width - cropSize) ~/ 2;
      final offsetY = (image.height - cropSize) ~/ 2;
      final cropped = img.copyCrop(
        image,
        x: offsetX,
        y: offsetY,
        width: cropSize,
        height: cropSize,
      );

      final encoded = img.encodeJpg(cropped, quality: QUALITY_HIGH);
      final fileName = xFile.name.isEmpty ? 'profile_crop.jpg' : xFile.name;
      final tempPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName';
      final outFile = File(tempPath);
      await outFile.writeAsBytes(encoded, flush: true);

      return XFile(outFile.path);
    } catch (e) {
      debugPrint("❌ Error cropping image: $e");
      return null;
    }
  }

  /// Validate image file (type and size)
  /// Returns validation result with error message if invalid
  static Future<ImageValidationResult> validateImage(XFile xFile) async {
    try {
      // Check file type
      final fileName = xFile.name.toLowerCase();
      final isValidType =
          fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png') ||
          fileName.endsWith('.webp');

      if (!isValidType) {
        return ImageValidationResult(
          isValid: false,
          errorCode: 'INVALID_FILE_TYPE',
          errorMessage: 'Only JPG, JPEG, PNG, and WEBP files are allowed.',
        );
      }

      // Check file size
      final fileSize = await getImageFileSizeBytes(xFile);
      if (fileSize == null) {
        return ImageValidationResult(
          isValid: false,
          errorCode: 'FILE_READ_ERROR',
          errorMessage: 'Failed to read file.',
        );
      }

      if (isFileTooLarge(fileSize)) {
        return ImageValidationResult(
          isValid: false,
          errorCode: 'FILE_TOO_LARGE',
          errorMessage:
              'File size (${getFileSizeDisplay(fileSize)}) exceeds the maximum allowed size (${getMaxFileSizeDisplay()}).',
          fileSizeBytes: fileSize,
        );
      }

      return ImageValidationResult(isValid: true, fileSizeBytes: fileSize);
    } catch (e) {
      return ImageValidationResult(
        isValid: false,
        errorCode: 'VALIDATION_ERROR',
        errorMessage: 'Error validating image: $e',
      );
    }
  }
}

/// Result of image validation
class ImageValidationResult {
  final bool isValid;
  final String? errorCode;
  final String? errorMessage;
  final int? fileSizeBytes;

  ImageValidationResult({
    required this.isValid,
    this.errorCode,
    this.errorMessage,
    this.fileSizeBytes,
  });

  @override
  String toString() {
    if (isValid) {
      return 'ImageValidationResult(isValid: true, fileSizeBytes: ${ImageUtils.getFileSizeDisplay(fileSizeBytes ?? 0)})';
    }
    return 'ImageValidationResult(isValid: false, errorCode: $errorCode, errorMessage: $errorMessage)';
  }
}
