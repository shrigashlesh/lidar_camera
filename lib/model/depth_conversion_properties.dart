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
    final extractedResult = _generateResizedImage1920x1080(depth);
    _resizedImage = extractedResult.$1;
    _orgDepthMap = extractedResult.$2;
  }

  @Matrix4Converter()
  @JsonKey(name: 'viewTransform')
  final Matrix4 transform;

  @Matrix3Converter()
  final Matrix3 cameraIntrinsic;

  @Uint8ListConverter()
  final Uint8List depth;

  late img.Image _resizedImage;
  late List<List<double>> _orgDepthMap;

  static DepthConversionProperties fromJson(Map<String, dynamic> json) =>
      _$DepthConversionPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$DepthConversionPropertiesToJson(this);

  @override
  String toString() =>
      'DepthConversionProperties(transform: $transform, cameraIntrinsic: $cameraIntrinsic, depth: $depth)';

  List<List<double>> get orginalDepthMap => _orgDepthMap;

  Uint8List get depthImage1920x1080 {
    // Use the cached resized image and return it as PNG
    Uint8List pngBytes = Uint8List.fromList(img.encodePng(_resizedImage));
    return pngBytes;
  }

// Static method to generate resized image
  static (img.Image, List<List<double>>) _generateResizedImage1920x1080(
      Uint8List depth) {
    final ByteData byteData = ByteData.sublistView(depth);

    // Extract original width and height from the depth data
    int originalWidth = 180; // Set the original width
    int originalHeight = 320; // Set the original height

    // Create an image with original dimensions
    img.Image image = img.Image(width: originalWidth, height: originalHeight);
    List<List<double>> depthMap = List.generate(
      originalHeight,
      (row) => List.generate(
        originalWidth,
        (col) {
          return 0;
        },
      ),
    );
    // Iterate over each pixel and convert depth data to grayscale
    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        int originalIndex = y * originalWidth + x;

        // Get the depth value as UInt16
        int accessAt = originalIndex * 2; // Each depth value is 2 bytes
        int depthValueRaw = byteData.getUint16(accessAt, Endian.little);

        // Convert the UInt16 value to a normalized float (assuming max depth is 65535)
        double depthValue = depthValueRaw / 65535.0;
        depthMap[y][x] = depthValue;
        // Convert normalized depth value to grayscale (0-255 range)
        int grayscale = (depthValue * 255).clamp(0, 255).toInt();

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

    return (resizedImage, depthMap);
  }
}
