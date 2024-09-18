import 'package:flutter/material.dart';
import 'package:lidar_camera/lidar_camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LidarCamera cam = LidarCamera();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            IconButton(
              onPressed: () async {
                final properties = await cam.readDepthConversionData(
                  at: 1.86,
                  fileName: "E850BB6A-0904-4776-8393-9D3987431EE6",
                );
                print(properties.toString());
              },
              icon: const Icon(Icons.abc),
            ),
          ],
        ),
        body: const LidarCameraView(),
      ),
    );
  }
}
