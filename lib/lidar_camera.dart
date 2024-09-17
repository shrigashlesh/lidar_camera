import 'package:lidar_camera/model/depth_conversion_properties.dart';

import 'lidar_camera_platform_interface.dart';
export './widget/lidar_camera_view.dart';

class LidarCamera {
  Future<bool?> checkLidarAvailability() {
    return LidarCameraPlatform.instance.checkLidarAvailability();
  }

  Future<DepthConversionProperties?> readDepthConversionData({
    required String fileName,
    required double at,
  }) async {
    try {
      final conversionData = await LidarCameraPlatform.instance
          .readDepthConversionData(fileName: fileName);
      if (conversionData == null) return null;

      // Parse all the keys into doubles
      final keys = conversionData.keys
          .map((key) => double.tryParse(key))
          .where((key) => key != null)
          .toList();

      if (keys.isEmpty) return null;

      // Sort keys in ascending order
      keys.sort();

      // Find the nearest key by comparing the difference with 'at'
      final nearestKey =
          keys.reduce((a, b) => (a! - at).abs() < (b! - at).abs() ? a : b);

      // Retrieve the data associated with the nearest key
      final nearestKeyString = nearestKey.toString();
      print(nearestKeyString);
      final propertiesAtTime = conversionData[nearestKeyString];
      print(propertiesAtTime["depth"].first.length);
      final properties = DepthConversionProperties.fromJson(propertiesAtTime);

      return properties;
    } catch (e) {
      print("ERROR $e");
    }
    return null;
  }
}
