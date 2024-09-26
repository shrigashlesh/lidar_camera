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
  }) {
    final extractedResult = _generateImageAndDepthArray(depth);
    _depthImage = extractedResult.$1;
    _orgDepthMap = extractedResult.$2;
  }

  @Matrix4Converter()
  @JsonKey(name: 'viewTransform')
  final Matrix4 transform;

  @Matrix3Converter()
  final Matrix3 cameraIntrinsic;

  @Uint8ListConverter()
  final Uint8List depth;

  late img.Image _depthImage;
  late List<List<double>> _orgDepthMap;

  static DepthConversionProperties fromJson(Map<String, dynamic> json) =>
      _$DepthConversionPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$DepthConversionPropertiesToJson(this);

  @override
  String toString() =>
      'DepthConversionProperties(transform: $transform, cameraIntrinsic: $cameraIntrinsic, depth: $depth)';

  List<List<double>> get originalDepthMap => _orgDepthMap;

  Uint8List get depthImage192x256 {
    // Use the cached resized image and return it as PNG
    Uint8List pngBytes = Uint8List.fromList(img.encodePng(_depthImage));
    return pngBytes;
  }

  static (img.Image, List<List<double>>) _generateImageAndDepthArray(
      Uint8List depth) {
    final ByteData byteData = ByteData.sublistView(depth);

    int originalWidth = 256;
    int originalHeight = 192;

    // Create image and depth map
    img.Image image = img.Image(width: originalWidth, height: originalHeight);
    List<List<double>> depthMap = List.generate(
      originalHeight,
      (row) => List.generate(
        originalWidth,
        (col) => 0.0,
      ),
    );

    // Fill image and depth map
    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        int originalIndex = y * originalWidth + x;
        int accessAt = originalIndex * 4;
        double depthValue = byteData.getFloat32(accessAt, Endian.little);
        depthMap[y][x] = depthValue;
        int grayscale = (depthValue / 5 * 255).clamp(0, 255).toInt();
        image.setPixelRgba(x, y, grayscale, grayscale, grayscale, 255);
      }
    }

    // Rotate depth map by 90 degrees
    List<List<double>> rotatedDepthMap = List.generate(
      originalWidth,
      (col) => List.generate(
        originalHeight,
        (row) => depthMap[originalHeight - row - 1][col],
      ),
    );

    // Rotate image by 90 degrees
    img.Image rotatedImage =
        img.Image(height: originalWidth, width: originalHeight);
    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        img.Pixel pixel = image.getPixel(x, y);
        rotatedImage.setPixel(originalHeight - 1 - y, x, pixel);
      }
    }

    return (rotatedImage, rotatedDepthMap);
  }
}
