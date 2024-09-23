import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:lidar_camera/utils/json_converter.dart';
import 'package:image/image.dart' as img;

part 'depth_conversion_properties.g.dart';

@JsonSerializable()
class DepthConversionProperties {
  DepthConversionProperties({
    required this.transform,
    required this.cameraIntrinsic,
    required this.depth,
    int? height,
    int? width,
  }) : _resizedImage = _generateResizedImage1920x1080(depth);

  @Matrix4Converter()
  @JsonKey(name: 'viewTransform')
  final Matrix4 transform;

  @Matrix3Converter()
  final Matrix3 cameraIntrinsic;

  @Uint8ListConverter()
  final Uint8List depth;

  final img.Image _resizedImage;

  static DepthConversionProperties fromJson(Map<String, dynamic> json) =>
      _$DepthConversionPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$DepthConversionPropertiesToJson(this);

  @override
  String toString() =>
      'DepthConversionProperties(transform: $transform, cameraIntrinsic: $cameraIntrinsic, depth: $depth)';

  List<List<double>> get depthMap1920x1080 {
    try {
      // Use the cached resized image for decoding
      img.Image resizedImage = _resizedImage;

      // Convert resized image back to 2D depth data
      List<List<double>> resizedDepthMap = List.generate(
        1920,
        (row) => List.generate(
          1080,
          (col) {
            img.Pixel pixel = resizedImage.getPixel(col, row);
            num r = pixel.r;
            return r / 255 * 5;
          },
        ),
      );

      return resizedDepthMap;
    } catch (e) {
      return [];
    }
  }

  Uint8List get depthImage1920x1080 {
    // Use the cached resized image and return it as PNG
    Uint8List pngBytes = Uint8List.fromList(img.encodePng(_resizedImage));
    return pngBytes;
  }

  // Static method to generate resized image
  static img.Image _generateResizedImage1920x1080(
    Uint8List depth,
  ) {
    final ByteData byteData = ByteData.sublistView(depth);

    // Extract original width and height from the depth data
    int originalWidth = byteData.getInt32(0, Endian.little);
    int originalHeight = byteData.getInt32(4, Endian.little);

    int depthDataStartIndex = 8; // Depth data starts after the width and height
    num maxDepthValue = 5; // Maximum expected depth value for normalization

    // Create an image with original dimensions
    img.Image image = img.Image(width: originalWidth, height: originalHeight);

    // Iterate over each pixel and convert depth data to grayscale
    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        int originalIndex = y * originalWidth + x;
        int accessAt = depthDataStartIndex + originalIndex * 4;

        // Get the depth value as a float (32-bit)
        double depthValue = byteData.getFloat32(accessAt, Endian.little);

        // Normalize the depth value to grayscale (0-255 range)
        int grayscale =
            (depthValue * 255 / maxDepthValue).clamp(0, 255).toInt();

        // Set the pixel color (grayscale) in the image
        image.setPixelRgba(x, y, grayscale, grayscale, grayscale, 255);
      }
    }

    // Resize the image with cubic interpolation
    final resizedImage = img.copyResize(
      image,
      height: 1920,
      width: 1080,
      maintainAspect: true,
      interpolation: img.Interpolation.cubic,
    );

    return resizedImage;
  }
}
