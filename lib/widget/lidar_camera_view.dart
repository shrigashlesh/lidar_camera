import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LidarCameraView extends StatelessWidget {
  const LidarCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const UiKitView(
        viewType: 'lidar_cam_view',
      );
    }

    return Text('$defaultTargetPlatform is not supported by this plugin');
  }
}
