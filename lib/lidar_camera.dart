import 'dart:developer';

import 'package:lidar_camera/model/depth_conversion_properties.dart';

import 'lidar_camera_platform_interface.dart';
export './widget/lidar_camera_view.dart';

class LidarCamera {
  Future<bool?> checkLidarAvailability() {
    return LidarCameraPlatform.instance.checkLidarAvailability();
  }

  Future<DepthConversionProperties?> readDepthConversionData({
    required String fileName,
    required int frameNumber,
  }) async {
    try {
      final conversionData =
          await LidarCameraPlatform.instance.readDepthConversionData(
        fileName: fileName,
        frameNumber: frameNumber,
      );
      if (conversionData == null) return null;
      final properties = DepthConversionProperties.fromJson(conversionData);

      return properties;
    } catch (e) {
      log("$e");
    }
    return null;
  }
}
