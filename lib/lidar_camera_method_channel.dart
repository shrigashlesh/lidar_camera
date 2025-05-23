import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lidar_camera_platform_interface.dart';

/// An implementation of [LidarCameraPlatform] that uses method channels.
class MethodChannelLidarCamera extends LidarCameraPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lidar/communication');

  /// The event channel used to interact with the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('lidar/stream');

  @override
  Future<bool?> isAvailable() async {
    final isAvailable = await methodChannel.invokeMethod<bool>('isAvailable');
    return isAvailable;
  }
}
