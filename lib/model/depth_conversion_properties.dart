// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:lidar_camera/utils/json_converter.dart';

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

// Decode depth data from byte array and return a 2D array (List of Lists)
  List<List<double>> decodeDepthData() {
    try {
      final ByteData byteData = ByteData.sublistView(depth);

      // Extract width and height from the byte data
      int width = byteData.getInt32(0, Endian.little);
      int height = byteData.getInt32(4, Endian.little);

      int depthDataStartIndex = 8; // Start index for the depth data

      // Initialize a 2D list for the depth map
      List<List<double>> depthMap =
          List.generate(height, (_) => List.filled(width, 0.0));

      // Read depth data and populate the 2D array
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          int index = row * width + col;
          int accessAt = depthDataStartIndex + index * 4;

          depthMap[row][col] = byteData.getFloat32(accessAt, Endian.little);
        }
      }

      return depthMap;
    } catch (e) {
      return [];
    }
  }
}
