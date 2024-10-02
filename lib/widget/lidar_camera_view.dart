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
  RecordingResultHandler? onRecordingCompleted;

  void dispose() {
    _channel.invokeMethod<void>('dispose');
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
        case 'onRecordingCompleted':
          if (onRecordingCompleted != null) {
            if (call.arguments != null) {
              final recordingPath = call.arguments["recordingPath"];
              final identifier = call.arguments["assetIdentifier"];
              if (recordingPath != null && identifier != null) {
                onRecordingCompleted!(
                  path: recordingPath,
                  identifier: identifier,
                );
              }
            }
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
