import Flutter
import UIKit

class FlutterLidarCameraView: NSObject, FlutterPlatformView {
    
    private var _view: UIView
    private weak var viewController: CameraViewController?
    private let channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self._view = UIView()
        self.channel = FlutterMethodChannel(name: "lidar/view_\(viewId)", binaryMessenger: messenger)
        super.init()
        createNativeView(binaryMessenger: messenger)
        channel.setMethodCallHandler(handleMethodCall)
    }

    func view() -> UIView {
        return _view
    }

    private func createNativeView(binaryMessenger messenger: FlutterBinaryMessenger) {
        guard let topController = UIApplication.shared.keyWindowPresentedController else {
            return
        }

        let vc = CameraViewController(messenger: messenger)
        self.viewController = vc

        let cameraView = vc.view!
        cameraView.translatesAutoresizingMaskIntoConstraints = false

        topController.addChild(vc)
        _view.addSubview(cameraView)

        NSLayoutConstraint.activate([
            cameraView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            cameraView.topAnchor.constraint(equalTo: _view.topAnchor),
            cameraView.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])

        vc.didMove(toParent: topController)
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecording":
            startRecording(result)
        case "stopRecording":
            stopRecording(result)
        case "startLidarRecording":
            startLidarRecording(result)
        case "stopLidarRecording":
            stopLidarRecording(result)
        case "dispose":
            onDispose(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController else {
            result(FlutterError(code: "UNAVAILABLE", message: "Camera controller not available", details: nil))
            return
        }

        cameraVC.startRecording { success in
            if success {
                result(success)
            } else {
                result(FlutterError(code: "RECORDING_ERROR", message: "Failed to start recording", details: nil))
            }
        }
    }

    private func stopRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController else {
            result(FlutterError(code: "UNAVAILABLE", message: "Camera controller not available", details: nil))
            return
        }

        cameraVC.stopRecording { recordingUUID in
            if let recordingUUID = recordingUUID {
                result(["recordingUUID": recordingUUID])
            } else {
                result(FlutterError(code: "STOP_RECORDING_ERROR", message: "Failed to stop recording", details: nil))
            }
        }
    }
    
    private func startLidarRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController else {
            result(FlutterError(code: "UNAVAILABLE", message: "Camera controller not available", details: nil))
            return
        }

        cameraVC.startLidarRecording { lidarDataStartMs in
            guard let lidarDataStartMs = lidarDataStartMs else {
                result(FlutterError(code: "LIDAR_RECORDING_ERROR", message: "Failed to start lidar recording", details: nil))
                return
            }

            // Convert CMTime to milliseconds
            result(["lidarDataStartMs":lidarDataStartMs])
        }
    }


    private func stopLidarRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController else {
            result(FlutterError(code: "UNAVAILABLE", message: "Camera controller not available", details: nil))
            return
        }

        cameraVC.stopLidarRecording { success in
            if success {
                result(success)
            } else {
                result(FlutterError(code: "STOP_LIDAR_RECORDING_ERROR", message: "Failed to stop lidar recording", details: nil))
            }
        }
    }


    private func onDispose(_ result: FlutterResult) {
        performDisposal()
        result(nil)
    }

    private func performDisposal() {
        channel.setMethodCallHandler(nil)

        if let vc = viewController {
            vc.cleanup()
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            viewController = nil
        }
    }

    func sendToFlutter(_ method: String, arguments: Any?) {
        DispatchQueue.main.async {
            self.channel.invokeMethod(method, arguments: arguments)
        }
    }

    func onRecordingCompleted(recordingUUID: String) {
        sendToFlutter("onRecordingCompleted", arguments: ["recordingUUID": recordingUUID])
    }

    deinit {
        performDisposal()
        print("FlutterLidarCameraView deinitialized")
    }
}
