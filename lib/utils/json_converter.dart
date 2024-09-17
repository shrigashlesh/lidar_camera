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
    return Matrix4.fromList(json.cast<double>());
  }

  @override
  List<dynamic> toJson(Matrix4 matrix) {
    final list = List.filled(16, 0.0);
    matrix.copyIntoArray(list);
    return list;
  }
}
