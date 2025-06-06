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
  List<String> selectedFiles = [];
  final LidarPlugin lidar = LidarPlugin();

  @override
  void initState() {
    super.initState();
  }

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
              ...List.generate(selectedFiles.length, (index) {
                return Card(
                  child: ListTile(
                    title: Text(
                      selectedFiles[index],
                    ),
                  ),
                );
              }),
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
                  final recordingUUID = fileName.split('.').first;
                  try {
                    final files = await lidar.fetchRecordingFiles(
                      recordingUUID: recordingUUID,
                    );
                    selectedFiles = files
                        .map((fileEntity) => fileEntity.path.split('/').last)
                        .toList();
                    setState(() {});
                  } catch (e) {
                    log(e.toString());
                  }
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

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late LidarRecordingController lidarRecordingController;
  bool isRecordingRGB = false;
  bool isRecordingLidar = false;

  @override
  void dispose() {
    lidarRecordingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Column(
        children: [
          Expanded(
            child: LidarCameraView(
              onRecordingControllerCreated: (controller) {
                lidarRecordingController = controller;
                lidarRecordingController.frameStream((frame) {
                  print(frame.toString());
                });
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (!isRecordingRGB) {
                      final didStart =
                          await lidarRecordingController.startRecording();
                      if (didStart ?? false) {
                        setState(() {
                          isRecordingRGB = true;
                        });
                      }
                    } else {
                      final recordingUUID =
                          await lidarRecordingController.stopRecording();
                      if (recordingUUID != null) {
                        setState(() {
                          isRecordingRGB = false;
                          isRecordingLidar = false;
                        });
                        log(recordingUUID);
                      }
                    }
                  },
                  child: Text(
                    "${isRecordingRGB ? "Stop" : "Start"} RGB Recording",
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (!isRecordingLidar) {
                      final startTimeInMs =
                          await lidarRecordingController.startLidarRecording();
                      if (startTimeInMs != null) {
                        log("LIDAR INFO TIME: ${startTimeInMs.toString()}");
                        setState(() {
                          isRecordingLidar = true;
                        });
                      }
                    } else {
                      final didStop =
                          await lidarRecordingController.stopLidarRecording();
                      if (didStop ?? false) {
                        setState(() {
                          isRecordingLidar = false;
                        });
                      }
                    }
                  },
                  child: Text(
                    "${isRecordingLidar ? "Stop" : "Start"} Lidar Recording",
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void onStop({
    required String path,
    required String identifier,
  }) async {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Video and data saved successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
            ],
          );
        });
  }
}
