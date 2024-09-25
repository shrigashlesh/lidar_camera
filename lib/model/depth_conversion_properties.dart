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
    _resizedDepthMap = extractedResult.$2;
  }

  @Matrix4Converter()
  @JsonKey(name: 'viewTransform')
  final Matrix4 transform;

  @Matrix3Converter()
  final Matrix3 cameraIntrinsic;

  @Uint8ListConverter()
  final Uint8List depth;

  late img.Image _resizedImage;
  late List<List<double>> _resizedDepthMap;

  static DepthConversionProperties fromJson(Map<String, dynamic> json) =>
      _$DepthConversionPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$DepthConversionPropertiesToJson(this);

  @override
  String toString() =>
      'DepthConversionProperties(transform: $transform, cameraIntrinsic: $cameraIntrinsic, depth: $depth)';

  List<List<double>> get originalDepthMap => _resizedDepthMap;

  Uint8List get depthImage1920x1080 {
    // Use the cached resized image and return it as PNG
    Uint8List pngBytes = Uint8List.fromList(img.encodePng(_resizedImage));
    return pngBytes;
  }

  static (img.Image, List<List<double>>) _generateResizedImage1920x1080(
      Uint8List depth) {
    final ByteData byteData = ByteData.sublistView(depth);

    int originalWidth = 180;
    int originalHeight = 320;

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

    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        int originalIndex = y * originalWidth + x;
        int accessAt = originalIndex * 4;
        double depthValue = byteData.getFloat32(accessAt, Endian.little);
        depthMap[y][x] = depthValue;
        int grayscale = (depthValue / 15 * 255).clamp(0, 255).toInt();
        image.setPixelRgba(x, y, grayscale, grayscale, grayscale, 255);
      }
    }

    // // Resize the depth map using bicubic interpolation
    // List<List<double>> resizedDepthMap =
    //     _resizeDepthMapBicubic(depthMap, 1080, 1920);

    final resizedImage = img.copyResize(
      image,
      height: 1920,
      width: 1080,
      maintainAspect: true,
      interpolation: img.Interpolation.cubic,
    );

    return (resizedImage, depthMap);
  }

  static List<List<double>> _resizeDepthMapBicubic(
      List<List<double>> originalDepthMap, int newWidth, int newHeight) {
    int originalHeight = originalDepthMap.length;
    int originalWidth = originalDepthMap[0].length;

    // Create a new depth map for the resized data
    List<List<double>> resizedDepthMap = List.generate(
      newHeight,
      (row) => List.generate(newWidth, (col) => 0.0),
    );

    // Bicubic interpolation formula, scaling factors
    double xRatio = originalWidth / newWidth;
    double yRatio = originalHeight / newHeight;

    for (int newY = 0; newY < newHeight; newY++) {
      for (int newX = 0; newX < newWidth; newX++) {
        // Map new pixel coordinates to original coordinates
        double origX = newX * xRatio;
        double origY = newY * yRatio;

        // Get the nearest 4x4 neighborhood around the original pixel
        int x0 = origX.floor();
        int y0 = origY.floor();

        // Ensure indices are within bounds
        x0 = x0.clamp(0, originalWidth - 2);
        y0 = y0.clamp(0, originalHeight - 2);

        // Perform bicubic interpolation for this pixel
        resizedDepthMap[newY][newX] = _bicubicInterpolation(
            originalDepthMap, x0, y0, origX - x0, origY - y0);
      }
    }

    return resizedDepthMap;
  }

  static double _bicubicInterpolation(
      List<List<double>> map, int x, int y, double dx, double dy) {
    double result = 0.0;
    for (int m = -1; m <= 2; m++) {
      for (int n = -1; n <= 2; n++) {
        int xi = (x + m).clamp(0, map[0].length - 1);
        int yi = (y + n).clamp(0, map.length - 1);
        double weightX = _bicubicWeight(dx - m);
        double weightY = _bicubicWeight(dy - n);
        result += map[yi][xi] * weightX * weightY;
      }
    }
    return result;
  }

  static double _bicubicWeight(double t) {
    // Cubic interpolation weights
    t = t.abs();
    if (t <= 1) {
      return 1.5 * t * t * t - 2.5 * t * t + 1;
    } else if (t <= 2) {
      return -0.5 * t * t * t + 2.5 * t * t - 4 * t + 2;
    } else {
      return 0;
    }
  }
}
