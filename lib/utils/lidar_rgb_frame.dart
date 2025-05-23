import 'dart:typed_data';
import 'package:flutter/services.dart';

class LidarRgbFrame {
  final Uint8List frameBytes;
  final int width;
  final int height;

  LidarRgbFrame({
    required this.frameBytes,
    required this.width,
    required this.height,
  });

  factory LidarRgbFrame.fromMap(Map<dynamic, dynamic> map) {
    final frameBytes = map['frameBytes'];
    final width = map['width'];
    final height = map['height'];

    if (frameBytes is Uint8List && width is int && height is int) {
      return LidarRgbFrame(
        frameBytes: frameBytes,
        width: width,
        height: height,
      );
    } else {
      throw const FormatException('Invalid LidarRgbFrame data received');
    }
  }
}
