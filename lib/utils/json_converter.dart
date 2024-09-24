import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

class Matrix3Converter implements JsonConverter<Matrix3, List<dynamic>> {
  const Matrix3Converter();

  @override
  Matrix3 fromJson(List<dynamic> json) {
    return Matrix3.fromList(json.cast<num>().map((e) => e.toDouble()).toList());
  }

  @override
  List<num> toJson(Matrix3 matrix) {
    final list = List.filled(9, 0.0);
    matrix.copyIntoArray(list);
    return list;
  }
}

class Matrix4Converter implements JsonConverter<Matrix4, List<dynamic>> {
  const Matrix4Converter();

  @override
  Matrix4 fromJson(List<dynamic> json) {
    return Matrix4(
        json[0],
        json[3],
        json[6],
        json[9],
        json[1],
        json[4],
        json[7],
        json[10],
        json[2],
        json[5],
        json[8],
        json[11],
        0.0,
        0.0,
        0.0,
        1.0);
  }

  @override
  List<dynamic> toJson(Matrix4 matrix) {
    final list = List.filled(16, 0.0);
    matrix.copyIntoArray(list);
    return list;
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
