import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lidar_camera/utils/lidar_rgb_frame.dart';

typedef LidarRecordingControllerCreatedCallback = void Function(
    LidarRecordingController controller);

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
        viewType: 'lidar/view',
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
    _channel = MethodChannel('lidar/view_$id');
    _eventChannel = EventChannel('lidar/stream');
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  late MethodChannel _channel;
  late EventChannel _eventChannel;
  StringResultHandler? onError;
  StreamSubscription? _streamSubscription;

  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
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

  /// Stops the current recording and returns the recording identifier.
  ///
  /// Returns a [Future] with the recording UUID.
  /// Throws a [PlatformException] if stopping the recording fails.
  Future<String> stopRecording() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('stopRecording');

      if (result == null) {
        throw 'Failed to stop recording: No result returned';
      }

      final recordingUUID = result['recordingUUID'] as String?;

      if (recordingUUID == null) {
        throw 'Failed to stop recording: Missing path or identifier';
      }

      return recordingUUID;
    } on PlatformException catch (e) {
      throw 'Failed to stop recording: ${e.message}';
    }
  }

  /// Listen to LiDAR camera stream data directly from the native side.
  ///
  /// The [onData] callback provides a [LidarRgbFrame] frame.
  /// Call this after the controller is created to start receiving frames.
  void frameStream(void Function(LidarRgbFrame frame) onData) {
    _streamSubscription?.cancel();
    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          if (event is Map) {
            final frame = LidarRgbFrame.fromMap(event);
            onData(frame);
          }
        } catch (e) {
          debugPrint('Error parsing CameraFrame: $e');
        }
      },
      onError: (error) {
        debugPrint('Stream error: $error');
      },
    );
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
