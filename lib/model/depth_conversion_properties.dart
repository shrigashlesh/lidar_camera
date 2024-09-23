// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:lidar_camera/utils/json_converter.dart';
import 'package:image/image.dart' as img;

part 'depth_conversion_properties.g.dart';

@JsonSerializable()
class DepthConversionProperties {
  const DepthConversionProperties({
    required this.transform,
    required this.cameraIntrinsic,
    required this.depth,
  });

  @Matrix4Converter()
  @JsonKey(name: 'viewTransform')
  final Matrix4 transform;

  @Matrix3Converter()
  final Matrix3 cameraIntrinsic;

  @Uint8ListConverter()
  final Uint8List depth;

  static DepthConversionProperties fromJson(Map<String, dynamic> json) =>
      _$DepthConversionPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$DepthConversionPropertiesToJson(this);

  @override
  String toString() =>
      'DepthConversionProperties(transform: $transform, cameraIntrinsic: $cameraIntrinsic, depth: $depth)';

  List<List<double>> decodeDepthData({
    required int height,
    required int width,
  }) {
    try {
      img.Image resizedImage = _depthImageResized(
        height: height,
        width: width,
      );

      // Convert resized image back to 2D depth data
      List<List<double>> resizedDepthMap = List.generate(
        height,
        (row) => List.generate(
          width,
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

  Uint8List depthImageResized({
    int? height,
    int? width,
  }) {
    final resizedImage = _depthImageResized(
      height: height,
      width: width,
    );

    // Encode the resized image to PNG format
    Uint8List pngBytes = Uint8List.fromList(img.encodePng(resizedImage));

    return pngBytes;
  }

  img.Image _depthImageResized({
    int? height,
    int? width,
  }) {
    // Extract the depth data from the ByteData view
    final ByteData byteData = ByteData.sublistView(depth);

    // Extract the original width and height directly from the depth map
    int originalWidth = byteData.getInt32(0, Endian.little);
    int originalHeight = byteData.getInt32(4, Endian.little);

    int depthDataStartIndex = 8; // Depth data starts after the width and height
    num maxDepthValue = 5; // Maximum expected depth value for normalization

    // Create an Image object with the original dimensions using the image package
    img.Image image = img.Image(width: originalWidth, height: originalHeight);

    // Iterate over each pixel to convert depth data to grayscale
    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        int originalIndex = y * originalWidth + x;
        int accessAt = depthDataStartIndex + originalIndex * 4;

        // Get the depth value as a float (32-bit)
        double depthValue = byteData.getFloat32(accessAt, Endian.little);

        // Normalize the depth value to grayscale (0-255 range)
        int grayscale =
            (depthValue * 255 / maxDepthValue).clamp(0, 255).toInt();

        // Set the pixel color in grayscale in the image
        image.setPixelRgba(x, y, grayscale, grayscale, grayscale, 255);
      }
    }

    // Resize the image to the desired dimensions
    final resizedImage = img.copyResize(
      image,
      height: height ?? originalHeight,
      width: width ?? originalWidth,
      maintainAspect: true,
      interpolation: img.Interpolation.cubic,
    );

    return resizedImage;
  }
}
