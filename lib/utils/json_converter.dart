// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

class Dimension {
  final int height;
  final int width;
  const Dimension({
    required this.height,
    required this.width,
  });
}

class DimensionConverter implements JsonConverter<Dimension, List<int>> {
  const DimensionConverter();

  @override
  Dimension fromJson(List<dynamic> json) {
    // Expecting json to be in the format [height, width]
    return Dimension(height: json[0], width: json[1]);
  }

  @override
  List<int> toJson(Dimension dimension) {
    // Return the size as [height, width]
    return [dimension.height, dimension.width];
  }
}

class Matrix3Converter implements JsonConverter<Matrix3, List<List<num>>> {
  const Matrix3Converter();

  @override
  Matrix3 fromJson(List<dynamic> json) {
    // Ensure correct casting
    final flatList = json
        .map((row) => (row as List<dynamic>).cast<num>())
        .expand((row) => row)
        .map((e) => e.toDouble())
        .toList();

    return Matrix3.fromList(flatList)..transpose();
  }

  @override
  List<List<num>> toJson(Matrix3 matrix) {
    final list = List.filled(9, 0.0);
    matrix.copyIntoArray(list);

    // Convert flat list into a 3x3 nested list
    return [
      [list[0], list[1], list[2]],
      [list[3], list[4], list[5]],
      [list[6], list[7], list[8]]
    ];
  }
}

class Matrix4Converter implements JsonConverter<Matrix4, List<List<num>>> {
  const Matrix4Converter();

  @override
  Matrix4 fromJson(List<dynamic> json) {
    // Ensure correct casting
    final flatList = json
        .map((row) => (row as List<dynamic>).cast<num>())
        .expand((row) => row)
        .map((e) => e.toDouble())
        .toList();

    return Matrix4.fromList(flatList)..transpose();
  }

  @override
  List<List<num>> toJson(Matrix4 matrix) {
    final list = List.filled(16, 0.0);
    matrix.copyIntoArray(list);

    // Convert flat list into a 4x4 nested list
    return [
      [list[0], list[1], list[2], list[3]],
      [list[4], list[5], list[6], list[7]],
      [list[8], list[9], list[10], list[11]],
      [list[12], list[13], list[14], list[15]]
    ];
  }
}

class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String source) {
    return base64Decode(source);
  }

  @override
  String toJson(Uint8List data) {
    return base64Encode(data);
  }
}
