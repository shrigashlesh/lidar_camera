import 'package:flutter_test/flutter_test.dart';
import 'package:lidar_camera/lidar_camera.dart';
import 'package:lidar_camera/lidar_camera_platform_interface.dart';
import 'package:lidar_camera/lidar_camera_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLidarCameraPlatform
    with MockPlatformInterfaceMixin
    implements LidarCameraPlatform {
  @override
  Future<bool?> checkLidarAvailability() => Future.value(true);
  @override
  Future<bool?> checkRecordingDataAvailability({
    required String recordingUUID,
  }) =>
      Future.value(true);

  @override
  Future<Map<String, dynamic>?> readDepthConversionData({
    required String recordingUUID,
    required int frameNumber,
  }) {
    return Future.value({});
  }

  @override
  Future<bool> deleteRecording({
    required String assetIdentifier,
    required String recordingUUID,
  }) {
    return Future.value(true);
  }
}

void main() {
  final LidarCameraPlatform initialPlatform = LidarCameraPlatform.instance;

  test('$MethodChannelLidarCamera is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLidarCamera>());
  });

  test('checkLidarAvailability', () async {
    LidarDepthPlugin lidarCameraPlugin = LidarDepthPlugin();
    MockLidarCameraPlatform fakePlatform = MockLidarCameraPlatform();
    LidarCameraPlatform.instance = fakePlatform;

    expect(await lidarCameraPlugin.checkLidarAvailability(), true);
  });
}
