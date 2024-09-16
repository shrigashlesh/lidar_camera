import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lidar_camera/lidar_camera_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelLidarCamera platform = MethodChannelLidarCamera();
  const MethodChannel channel = MethodChannel('lidar_camera');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('checkLidarAvailability', () async {
    expect(await platform.checkLidarAvailability(), '42');
  });
}
