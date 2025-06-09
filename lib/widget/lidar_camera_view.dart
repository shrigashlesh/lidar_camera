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
    _eventChannel = const EventChannel('lidar/stream');
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  late MethodChannel _channel;
  late EventChannel _eventChannel;
  StringResultHandler? onError;
  StreamSubscription? _streamSubscription;

  /// Call this to wait until the native side is fully initialized.
  final Completer<void> _initialized = Completer<void>();

  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _channel.invokeMethod<void>('dispose');
  }

  /// Starts recording RGB camera data.
  ///
  /// Returns a [Future<bool>] indicating whether recording started successfully.
  /// Throws a [PlatformException] if recording fails to start.
  Future<bool?> startRecording() async {
    try {
      final result = await _channel.invokeMethod<bool>('startRecording');

      return result;
    } on PlatformException catch (e) {
      throw 'Failed to start recording: ${e.message}';
    }
  }

  /// Stops the current recording and returns the recording identifier.
  ///
  /// Returns a [Future] with the recording UUID.
  /// Throws a [PlatformException] if stopping the recording fails.
  Future<String?> stopRecording() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('stopRecording');

      if (result == null) {
        throw 'Failed to stop recording: No result returned';
      }

      final recordingUUID = result['recordingUUID'] as String?;

      return recordingUUID;
    } on PlatformException catch (e) {
      throw 'Failed to stop recording: ${e.message}';
    }
  }

  /// Starts recording LiDAR lidar data.
  ///
  /// Returns a [Future] that completes when lidar recording has started.
  /// Throws a [PlatformException] if lidar recording fails to start.
  Future<int?> startLidarRecording() async {
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('startLidarRecording');

      if (result == null) {
        throw 'Failed to start lidar recording: No result returned';
      }

      final lidarDataStartMs = result['lidarDataStartMs'] as int?;

      return lidarDataStartMs;
    } on PlatformException catch (e) {
      throw 'Failed to start lidar recording: ${e.message}';
    }
  }

  /// Stops the current lidar data recording.
  ///
  /// Returns a [Future<bool?>] indicating whether lidar recording stopped.
  /// Throws a [PlatformException] if stopping the lidar recording fails.
  Future<bool?> stopLidarRecording() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopLidarRecording');

      return result;
    } on PlatformException catch (e) {
      throw 'Failed to stop lidar recording: ${e.message}';
    }
  }

  /// Listen to LiDAR camera stream data directly from the native side.
  ///
  /// The [onData] callback provides a [LidarRgbFrame] frame.
  /// Call this after the controller is created to start receiving frames.
  Future<void> frameStream(void Function(LidarRgbFrame frame) onData) async {
    // Wait for native side to be ready
    await _initialized.future;

    // Cancel any existing subscription
    _streamSubscription?.cancel();

    // Set up the stream with proper error handling
    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          if (event is Map) {
            final frame = LidarRgbFrame.fromMap(event);
            onData(frame);
          }
        } catch (e) {
          debugPrint('Error parsing LidarRgbFrame: $e');
        }
      },
      onError: (error) {
        debugPrint('Stream error: $error');
      },
    );
  }

  Future<void> _platformCallHandler(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onError':
          onError?.call(call.arguments);
          break;
        case 'onViewInitialized':
          if (!_initialized.isCompleted) _initialized.complete();
          break;
      }
    } catch (e) {
      debugPrint('Platform call error: $e');
    }
  }
}
