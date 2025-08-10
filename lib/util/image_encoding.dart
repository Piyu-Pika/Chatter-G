import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageEncoding {
  // In-memory cache for decoded images
  static final Map<String, Uint8List> _imageCache = {};

  // Target size thresholds in KB
  static const int _largeImageThreshold = 1024; // 1MB
  static const int _mediumImageThreshold = 512; // 512KB

  static String encodeImage(Uint8List image, {int quality = 85}) {
    // Compress the image before encoding with adaptive quality
    final compressedImage = compressImage(image, quality: quality);
    return base64Encode(compressedImage);
  }

  static Uint8List decodeImage(String image) {
    // Check cache first
    if (_imageCache.containsKey(image)) {
      return _imageCache[image]!;
    }

    // Decode the image and enhance it
    final decodedImage = base64Decode(image);
    final enhancedImage = enhanceImage(decodedImage);

    // Store in cache
    _imageCache[image] = enhancedImage;
    return enhancedImage;
  }

  static Uint8List decodeImageForPreview(String image, {int maxSize = 100}) {
    final cacheKey = "preview_$maxSize$image";

    // Check cache first
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    // Decode without enhancement for faster preview
    final decodedImage = base64Decode(image);
    final imgImage = img.decodeImage(decodedImage);
    if (imgImage == null) {
      throw Exception("Invalid image data");
    }

    // Resize for thumbnail (maintain aspect ratio)
    int targetWidth = maxSize;
    int targetHeight = maxSize;

    if (imgImage.width > imgImage.height) {
      targetHeight = (maxSize * imgImage.height / imgImage.width).round();
    } else {
      targetWidth = (maxSize * imgImage.width / imgImage.height).round();
    }

    final resizedImage = img.copyResize(
      imgImage,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average,
    );

    final result = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 70));

    // Store in cache
    _imageCache[cacheKey] = result;
    return result;
  }

  static Uint8List decodeImageForFullScreen(String image) {
    final cacheKey = "fullscreen_$image";

    // Check cache first
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    // Decode and apply moderate compression to save memory
    final decodedImage = base64Decode(image);
    final imgImage = img.decodeImage(decodedImage);

    if (imgImage == null) {
      throw Exception("Invalid image data");
    }

    // Apply moderate compression for full screen viewing
    final result = Uint8List.fromList(img.encodeJpg(imgImage, quality: 90));

    // Store in cache
    _imageCache[cacheKey] = result;
    return result;
  }

  static Uint8List compressImage(Uint8List image, {int quality = 85}) {
    final decodedImage = img.decodeImage(image);
    if (decodedImage == null) {
      throw Exception("Invalid image data");
    }

    // Get original size in KB
    final originalSizeKB = image.length ~/ 1024;

    // Adaptive quality based on image size
    int adaptiveQuality = quality;
    int targetWidth = decodedImage.width;
    int targetHeight = decodedImage.height;

    // Apply more aggressive compression for larger images
    if (originalSizeKB > _largeImageThreshold) {
      adaptiveQuality = 70;

      // Downscale large images
      if (decodedImage.width > 2048 || decodedImage.height > 2048) {
        double scaleFactor =
            2048 / max(decodedImage.width, decodedImage.height);
        targetWidth = (decodedImage.width * scaleFactor).round();
        targetHeight = (decodedImage.height * scaleFactor).round();
      }
    } else if (originalSizeKB > _mediumImageThreshold) {
      adaptiveQuality = 75;

      // Moderate downscaling for medium images
      if (decodedImage.width > 1536 || decodedImage.height > 1536) {
        double scaleFactor =
            1536 / max(decodedImage.width, decodedImage.height);
        targetWidth = (decodedImage.width * scaleFactor).round();
        targetHeight = (decodedImage.height * scaleFactor).round();
      }
    }

    // Resize if needed
    img.Image processedImage = decodedImage;
    if (targetWidth != decodedImage.width ||
        targetHeight != decodedImage.height) {
      processedImage = img.copyResize(
        decodedImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    // Use JPEG encoding as WebP is not supported
    return Uint8List.fromList(img.encodeJpg(
      processedImage,
      quality: adaptiveQuality,
    ));
  }

  static Uint8List enhanceImage(Uint8List image) {
    final decodedImage = img.decodeImage(image);
    if (decodedImage == null) {
      throw Exception("Invalid image data");
    }

    // Apply subtle enhancements to avoid quality loss
    final enhancedImage = img.adjustColor(
      decodedImage,
      brightness: 1.05,
      contrast: 1.1,
      saturation: 1.05,
    );

    // Use moderate quality to maintain balance between quality and size
    return Uint8List.fromList(img.encodeJpg(enhancedImage, quality: 90));
  }

  // Clear all cache to free memory
  static void clearCache() {
    _imageCache.clear();
  }

  // Clear specific image from cache
  static void removeFromCache(String imageKey) {
    _imageCache.remove(imageKey);
    _imageCache.remove("preview_$imageKey");
    _imageCache.remove("fullscreen_$imageKey");
  }

  // Utility function to get max value
  static int max(int a, int b) {
    return a > b ? a : b;
  }
}
