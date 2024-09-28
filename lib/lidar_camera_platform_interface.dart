import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'lidar_camera_method_channel.dart';

abstract class LidarCameraPlatform extends PlatformInterface {
  /// Constructs a LidarCameraPlatform.
  LidarCameraPlatform() : super(token: _token);

  static final Object _token = Object();

  static LidarCameraPlatform _instance = MethodChannelLidarCamera();

  /// The default instance of [LidarCameraPlatform] to use.
  ///
  /// Defaults to [MethodChannelLidarCamera].
  static LidarCameraPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LidarCameraPlatform] when
  /// they register themselves.
  static set instance(LidarCameraPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool?> checkLidarAvailability() {
    throw UnimplementedError(
        'checkLidarAvailability() has not been implemented.');
  }

  /// Extracts depth conversion data for the given video (from its unique filename) at the specified time.
  Future<Map<String, dynamic>?> readDepthConversionData({
    required String recordingUUID,
    required int frameNumber,
  }) {
    throw UnimplementedError(
        'readDepthConversionData() has not been implemented.');
  }
}
