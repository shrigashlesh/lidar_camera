import 'package:flutter/services.dart';
import 'package:lidar_camera/model/depth_conversion_properties.dart';

import 'lidar_camera_platform_interface.dart';
export './widget/lidar_camera_view.dart';
export './utils/json_converter.dart';

class LidarDepthReader {
  Future<bool?> checkLidarAvailability() {
    return LidarCameraPlatform.instance.checkLidarAvailability();
  }

  Future<DepthConversionProperties?> readDepthConversionData({
    required String recordingUUID,
    required int frameNumber,
  }) async {
    try {
      final conversionData =
          await LidarCameraPlatform.instance.readDepthConversionData(
        recordingUUID: recordingUUID,
        frameNumber: frameNumber,
      );
      if (conversionData == null) return null;
      final properties = DepthConversionProperties.fromJson(conversionData);

      return properties;
    } on PlatformException catch (e) {
      throw DepthReaderException(code: e.code);
    } catch (_) {
      rethrow;
    }
  }
}
