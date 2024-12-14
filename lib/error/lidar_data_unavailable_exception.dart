class LidarDataUnavailableException implements Exception {
  @override
  String toString() {
    return "Lidar data unavailable for the selected recording.";
  }
}
