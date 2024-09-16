import 'lidar_camera_platform_interface.dart';
export './widget/lidar_camera_view.dart';

class LidarCamera {
  Future<bool?> checkLidarAvailability() {
    return LidarCameraPlatform.instance.checkLidarAvailability();
  }
}
