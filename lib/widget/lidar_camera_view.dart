import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef LidarRecordingControllerCreatedCallback = void Function(
    LidarRecordingController controller);
typedef RecordingResultHandler = void Function({
  required String path,
  required String identifier,
});
typedef StringResultHandler = void Function(String? error);

class LidarCameraView extends StatefulWidget {
  const LidarCameraView({
    super.key,
    required this.onRecordingControllerCreated,
  });
  final LidarRecordingControllerCreatedCallback onRecordingControllerCreated;
  @override
  State<LidarCameraView> createState() => _LidarCameraViewState();
}

class _LidarCameraViewState extends State<LidarCameraView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'lidar_cam_view',
        onPlatformViewCreated: onPlatformViewCreated,
      );
    }

    return Text('$defaultTargetPlatform is not supported by this plugin');
  }

  Future<void> onPlatformViewCreated(int id) async {
    widget.onRecordingControllerCreated(LidarRecordingController._init(
      id: id,
    ));
  }
}

/// Controls an [LidarCameraView].
///
/// An [LidarRecordingController] instance can be obtained by setting the [LidarCameraView.]
/// callback for an [LidarCameraView] widget.
class LidarRecordingController {
  LidarRecordingController._init({
    required int id,
  }) {
    _channel = MethodChannel('lidar_camera_$id');
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  late MethodChannel _channel;
  StringResultHandler? onError;

  void dispose() {
    _channel.invokeMethod<void>('dispose');
  }

  /// Starts recording LiDAR camera data.
  ///
  /// Returns a [Future] that completes when recording has started.
  /// Throws a [PlatformException] if recording fails to start.
  Future<void> startRecording() async {
    try {
      await _channel.invokeMethod<void>('startRecording');
    } on PlatformException catch (e) {
      throw 'Failed to start recording: ${e.message}';
    }
  }

  /// Stops the current recording and returns the recording path and identifier.
  ///
  /// Returns a [Future] with a map containing the recording path and asset identifier.
  /// Throws a [PlatformException] if stopping the recording fails.
  Future<Map<String, String>> stopRecording() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('stopRecording');

      if (result == null) {
        throw 'Failed to stop recording: No result returned';
      }

      final recordingPath = result['recordingPath'] as String?;
      final assetIdentifier = result['assetIdentifier'] as String?;

      if (recordingPath == null || assetIdentifier == null) {
        throw 'Failed to stop recording: Missing path or identifier';
      }

      return {
        'recordingPath': recordingPath,
        'assetIdentifier': assetIdentifier,
      };
    } on PlatformException catch (e) {
      throw 'Failed to stop recording: ${e.message}';
    }
  }

  Future<void> _platformCallHandler(MethodCall call) {
    try {
      switch (call.method) {
        case 'onError':
          if (onError != null) {
            onError!(call.arguments);
            debugPrint(call.arguments);
          }
          break;
        default:
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return Future.value();
  }
}
