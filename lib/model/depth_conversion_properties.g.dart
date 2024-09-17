// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'depth_conversion_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepthConversionProperties _$DepthConversionPropertiesFromJson(
        Map<String, dynamic> json) =>
    DepthConversionProperties(
      transform:
          const Matrix3Converter().fromJson(json['viewTransform'] as List),
      cameraIntrinsic:
          const Matrix3Converter().fromJson(json['cameraIntrinsic'] as List),
    );

Map<String, dynamic> _$DepthConversionPropertiesToJson(
        DepthConversionProperties instance) =>
    <String, dynamic>{
      'viewTransform': const Matrix3Converter().toJson(instance.transform),
      'cameraIntrinsic':
          const Matrix3Converter().toJson(instance.cameraIntrinsic),
    };