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
          title: const Text('Plugin example app'),
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
    return Column(
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
    );
  }
}

class PickerView extends StatelessWidget {
  const PickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final List<AssetEntity>? result = await AssetPicker.pickAssets(
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
              fileName: cleanedName,
              frameNumber: 10,
            );
            print(properties.toString());
          },
          child: const Text("Pick Video"),
          // D33BAC4E-1514-40A9-B55A-59F290F321A3
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
