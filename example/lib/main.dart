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
                  frameNumber: 80,
                  fileName: "871CA6DD-3DD1-45D9-9DDB-8C957D158BFF",
                );

                final depth = properties!.decodeDepthData();
                print(depth);
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
