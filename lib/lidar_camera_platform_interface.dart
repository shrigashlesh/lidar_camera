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

  /// Check for lidar availability
  Future<bool?> isAvailable() {
    throw UnimplementedError('isAvailable() has not been implemented.');
  }

  /// Returns recording data (video, depth, confidence, intrinsics) for the given recording UUID.
  Future<List<String>?> listRecordingFiles({
    required String recordingUUID,
  }) {
    throw UnimplementedError('listRecordingFiles() has not been implemented.');
  }
}
