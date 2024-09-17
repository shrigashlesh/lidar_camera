// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:lidar_camera/utils/json_converter.dart';

part 'depth_conversion_properties.g.dart';

@JsonSerializable()
class DepthConversionProperties {
  const DepthConversionProperties({
    required this.transform,
    required this.cameraIntrinsic,
  });

  @Matrix3Converter()
  @JsonKey(name: 'viewTransform')
  final Matrix3 transform;

  @Matrix3Converter()
  final Matrix3 cameraIntrinsic;

  static DepthConversionProperties fromJson(Map<String, dynamic> json) =>
      _$DepthConversionPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$DepthConversionPropertiesToJson(this);

  @override
  String toString() =>
      'DepthConversionProperties(transform: $transform, cameraIntrinsic: $cameraIntrinsic)';
}
