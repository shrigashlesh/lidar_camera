// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'depth_conversion_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepthConversionProperties _$DepthConversionPropertiesFromJson(
        Map<String, dynamic> json) =>
    DepthConversionProperties(
      transform: const Matrix4Converter()
          .fromJson(json['transform'] as List<List<num>>),
      intrinsic: const Matrix3Converter()
          .fromJson(json['intrinsic'] as List<List<num>>),
      depth: const Uint8ListConverter().fromJson(json['depth'] as String),
      depthFilePath: json['depthFilePath'] as String,
    );

Map<String, dynamic> _$DepthConversionPropertiesToJson(
        DepthConversionProperties instance) =>
    <String, dynamic>{
      'transform': const Matrix4Converter().toJson(instance.transform),
      'intrinsic': const Matrix3Converter().toJson(instance.intrinsic),
      'depth': const Uint8ListConverter().toJson(instance.depth),
      'depthFilePath': instance.depthFilePath,
    };
