import 'dart:io';
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
    final extractedResult = _generateImage(depth);
    _image = extractedResult;
    // _orgDepthMap = extractedResult.$2;
  }

  @Matrix4Converter()
  @JsonKey(name: 'viewTransform')
  final Matrix4 transform;

  @Matrix3Converter()
  final Matrix3 cameraIntrinsic;

  @Uint8ListConverter()
  final Uint8List depth;

  late img.Image _image;
  static DepthConversionProperties fromJson(Map<String, dynamic> json) =>
      _$DepthConversionPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$DepthConversionPropertiesToJson(this);

  @override
  String toString() =>
      'DepthConversionProperties(transform: $transform, cameraIntrinsic: $cameraIntrinsic, depth: $depth)';

  saveImage(String output) {
    final tiffBytes = img.encodeTiff(_image);
    File file = File(output);
    file.writeAsBytes(tiffBytes);
  }

  num getDepthAt({required int x, required int y}) {
    final pixel = _image.getPixel(x, y);
    return pixel.r;
  }

  static img.Image _generateImage(Uint8List depth) {
    final ByteData byteData = ByteData.sublistView(depth);

    const width = 256;
    const height = 192;
    const numBytesPerFloat = 4;
    if (depth.length != width * height * numBytesPerFloat) {
      throw Exception(
          'Raw data size does not match expected 256x192 float32 format');
    }

    final orgImage = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: byteData.buffer,
      format: img.Format.float32,
      numChannels: 1,
    );

    // Rotate the image by 90 degrees clockwise
    final rotatedImage = img.copyRotate(orgImage, angle: 90);

    // Resize the rotated image to 1440x1920 using bicubic interpolation
    final resizedImage = img.copyResize(
      rotatedImage,
      width: 1440,
      height: 1920,
      interpolation: img.Interpolation.average,
    );

    return resizedImage;
  }
}
