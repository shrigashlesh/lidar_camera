import Flutter
import UIKit

class FlutterLidarCameraView: NSObject, FlutterPlatformView {
    
    private var _view: UIView
    private var viewController: UIViewController?
    let channel: FlutterMethodChannel
    let eventChannel: FlutterEventChannel
    var eventSink: FlutterEventSink?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        channel = FlutterMethodChannel(name: "lidar/view_\(viewId)", binaryMessenger: messenger)
        eventChannel = FlutterEventChannel(name: "lidar/stream", binaryMessenger: messenger)
        super.init()
        createNativeView(view: _view)
        channel.setMethodCallHandler(onMethodCalled)
    }

    
    func view() -> UIView {
        return _view
    }
    
    func createNativeView(view _view: UIView){
        let topController = UIApplication.shared.keyWindowPresentedController
        
        let vc = CameraViewController()
        viewController = vc // Store reference to view controller

        let uiKitView = vc.view!
        uiKitView.translatesAutoresizingMaskIntoConstraints = false
        
        topController?.addChild(vc)
        _view.addSubview(uiKitView)
        
        NSLayoutConstraint.activate(
            [
                uiKitView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                uiKitView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                uiKitView.topAnchor.constraint(equalTo: _view.topAnchor),
                uiKitView.bottomAnchor.constraint(equalTo:  _view.bottomAnchor)
            ])
        
        vc.didMove(toParent: topController)
    }
    
    func onMethodCalled(_ call: FlutterMethodCall, _ result:@escaping FlutterResult) {
        _ = call.arguments as? [String: Any]
        switch call.method {
        case "startRecording":
            startRecording(result)
        case "stopRecording":
            stopRecording(result)
        case "dispose":
            onDispose(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func startRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController as? CameraViewController else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Camera controller not available",
                                details: nil))
            return
        }
        
        cameraVC.startRecording { success in
            if success {
                result(nil)
            } else {
                result(FlutterError(code: "RECORDING_ERROR",
                                    message:  "Failed to start recording",
                                    details: nil))
            }
        }
    }
    
    func stopRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController as? CameraViewController else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Camera controller not available",
                                details: nil))
            return
        }
        
        cameraVC.stopRecording { recordingUUID in
            guard let recordingUUID = recordingUUID else { result(FlutterError(code: "STOP_RECORDING_ERROR",
                                                                               message: "Failed to stop recording",
                                                                               details: nil))
                return
            }
            result([
                "recordingUUID": recordingUUID,
            ])
        }
    }
    
    func onDispose(_ result: FlutterResult) {
        // Remove the method call handler
        channel.setMethodCallHandler(nil)
        
        // Cleanup viewController if it exists
        if let vc = viewController {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            viewController = nil
        }
        
        result(nil)
    }
    
    deinit {
        viewController?.willMove(toParent: nil)
        viewController?.view.removeFromSuperview()
        viewController?.removeFromParent()
        viewController = nil
    }
    
    func sendToFlutter(_ method: String, arguments: Any?) {
        DispatchQueue.main.async {
            self.channel.invokeMethod(method, arguments: arguments)
        }
    }
    
    func onRecordingCompleted(recordingUUID: String) {
        let arguments: [String: String] = ["recordingUUID": recordingUUID]
        sendToFlutter("onRecordingCompleted", arguments: arguments)
    }
}
