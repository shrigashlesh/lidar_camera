import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lidar_camera_platform_interface.dart';

/// An implementation of [LidarCameraPlatform] that uses method channels.
class MethodChannelLidarCamera extends LidarCameraPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lidar_data_reader');

  @override
  Future<bool?> checkLidarAvailability() async {
    final isAvailable =
        await methodChannel.invokeMethod<bool>('checkLidarAvailability');
    return isAvailable;
  }

  @override
  Future<bool> deleteRecording({
    required String assetIdentifier,
    required String recordingUUID,
  }) async {
    return await methodChannel.invokeMethod<bool>('deleteRecording', {
          'assetIdentifier': assetIdentifier,
          'recordingUUID': recordingUUID,
        }) ??
        false;
  }
}
