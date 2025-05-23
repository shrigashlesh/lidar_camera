import 'dart:io';

import 'package:lidar_camera/error/lidar_data_unavailable_exception.dart';
import 'package:path_provider/path_provider.dart';

import 'lidar_camera_platform_interface.dart';
export './widget/lidar_camera_view.dart';

class LidarPlugin {
  Future<bool?> isAvailable() => LidarCameraPlatform.instance.isAvailable();

  Future<List<FileSystemEntity>> fetchRecordingFiles({
    required String recordingUUID,
  }) async {
    try {
      // Get the application's document directory
      final appDirectory = await getApplicationDocumentsDirectory();

      // Define the recording directory path using the UUID
      final recordingDirectory =
          Directory('${appDirectory.path}/$recordingUUID');

      // Check if the directory exists and return the files or throw error accordingly
      if (await recordingDirectory.exists()) {
        final files = recordingDirectory.listSync();
        return files;
      } else {
        throw LidarDataUnavailableException();
      }
    } catch (_) {
      rethrow;
    }
  }
}
