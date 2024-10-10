import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:lidar_camera/model/depth_conversion_properties.dart';

import 'lidar_camera_platform_interface.dart';
export './widget/lidar_camera_view.dart';
export './utils/json_converter.dart';

class LidarDepthPlugin {
  Future<bool?> checkLidarAvailability() {
    return LidarCameraPlatform.instance.checkLidarAvailability();
  }

  Future<bool?> checkRecordingDataAvailability({
    required String recordingUUID,
  }) {
    return LidarCameraPlatform.instance.checkRecordingDataAvailability(
      recordingUUID: recordingUUID,
    );
  }

  Future<DepthConversionProperties> readDepthConversionData({
    required String recordingUUID,
    required int frameNumber,
  }) async {
    try {
      final conversionData =
          await LidarCameraPlatform.instance.readDepthConversionData(
        recordingUUID: recordingUUID,
        frameNumber: frameNumber,
      );
      if (conversionData == null) {
        throw DepthReaderException(code: "READ_ERROR");
      }
      final properties = DepthConversionProperties.fromJson(conversionData);

      return properties;
    } on PlatformException catch (e) {
      log(e.toString());
      throw DepthReaderException(code: e.code);
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> deleteRecording({
    required String recordingUUID,
    required String assetIdentifier,
  }) async {
    try {
      return await LidarCameraPlatform.instance.deleteRecording(
        assetIdentifier: assetIdentifier,
        recordingUUID: recordingUUID,
      );
    } catch (e) {
      rethrow;
    }
  }
}
