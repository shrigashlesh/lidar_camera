import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lidar_camera/lidar_camera.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lidar plugin example app'),
        ),
        body: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CameraView()));
            },
            child: const Text("Go to Camera"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PickerView()));
            },
            child: const Text("Go to Picker"),
          )
        ],
      ),
    );
  }
}

class PickerView extends StatefulWidget {
  const PickerView({super.key});

  @override
  State<PickerView> createState() => _PickerViewState();
}

class _PickerViewState extends State<PickerView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Picker View"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final List<AssetEntity>? result =
                      await AssetPicker.pickAssets(
                    context,
                    pickerConfig: const AssetPickerConfig(
                      maxAssets: 1,
                      shouldAutoplayPreview: true,
                      specialPickerType: SpecialPickerType.noPreview,
                      textDelegate: AssetPickerTextDelegate(),
                      requestType: RequestType.video,
                    ),
                  );
                  final file = result?.firstOrNull;
                  if (file == null) return;
                  final fileName = await file.titleAsync;
                  final cleanedName = fileName.split('.').first;
                  final LidarCamera cam = LidarCamera();
                  final properties = await cam.readDepthConversionData(
                    recordingUUID: cleanedName,
                    frameNumber: 12,
                  );
                  if (properties == null) return;
                  log(properties.toString());
                  if (!mounted) return;
                },
                child: const Text("Pick Video"),
              ),
              const SizedBox(
                height: 20,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: LidarCameraView(),
    );
  }
}
