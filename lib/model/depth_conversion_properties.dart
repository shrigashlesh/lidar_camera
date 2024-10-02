import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:lidar_camera/utils/json_converter.dart';

part 'depth_conversion_properties.g.dart';

class DepthReaderException extends PlatformException {
  DepthReaderException({required super.code});

  @override
  String toString() {
    return "Reading the depth properties failed. Please try with a different video.";
  }
}

class DepthDeletionException extends PlatformException {
  DepthDeletionException({required super.code});

  @override
  String toString() {
    return "Deleting the depth properties failed.";
  }
}

@JsonSerializable()
class DepthConversionProperties {
  DepthConversionProperties({
    required this.transform,
    required this.intrinsic,
    required this.depth,
    required this.depthFilePath,
  });

  @Matrix4Converter()
  final Matrix4 transform;

  @Matrix3Converter()
  final Matrix3 intrinsic;

  @Uint8ListConverter()
  final Uint8List depth;

  final String depthFilePath;

  static DepthConversionProperties fromJson(Map<String, dynamic> json) =>
      _$DepthConversionPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$DepthConversionPropertiesToJson(this);

  @override
  String toString() {
    return 'DepthConversionProperties(transform: $transform, intrinsic: $intrinsic, depth: $depth, depthFilePath: $depthFilePath)';
  }
}
