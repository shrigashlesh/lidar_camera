import Flutter
import UIKit

class FlutterLidarCameraView: NSObject, FlutterPlatformView {
    
    private var _view: UIView
    private var viewController: UIViewController?
    let channel: FlutterMethodChannel
    private var isDisposed = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        channel = FlutterMethodChannel(name: "lidar/view_\(viewId)", binaryMessenger: messenger)
        super.init()
        viewController = CameraViewController(messenger: messenger)
        createNativeView(view: _view)
        channel.setMethodCallHandler(onMethodCalled)
    }

    
    func view() -> UIView {
        return _view
    }
    
    func createNativeView(view _view: UIView){
        guard let viewController = viewController else { return }
        let topController = UIApplication.shared.keyWindowPresentedController
        
        

        let uiKitView = viewController.view!
        uiKitView.translatesAutoresizingMaskIntoConstraints = false
        
        topController?.addChild(viewController)
        _view.addSubview(uiKitView)
        
        NSLayoutConstraint.activate(
            [
                uiKitView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                uiKitView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                uiKitView.topAnchor.constraint(equalTo: _view.topAnchor),
                uiKitView.bottomAnchor.constraint(equalTo:  _view.bottomAnchor)
            ])
        
        viewController.didMove(toParent: topController)
    }
    
    func onMethodCalled(_ call: FlutterMethodCall, _ result:@escaping FlutterResult) {
        // Check if already disposed
        guard !isDisposed else {
            result(FlutterError(code: "DISPOSED",
                                message: "View has been disposed",
                                details: nil))
            return
        }
        
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
        guard !isDisposed else {
            result(FlutterError(code: "DISPOSED",
                                message: "View has been disposed",
                                details: nil))
            return
        }
        
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
        guard !isDisposed else {
            result(FlutterError(code: "DISPOSED",
                                message: "View has been disposed",
                                details: nil))
            return
        }
        
        guard let cameraVC = viewController as? CameraViewController else {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Camera controller not available",
                                details: nil))
            return
        }
        
        cameraVC.stopRecording { recordingUUID in
            guard let recordingUUID = recordingUUID else {
                result(FlutterError(code: "STOP_RECORDING_ERROR",
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
        performDisposal()
        result(nil)
    }
    
    private func performDisposal() {
        guard !isDisposed else { return }
        
        isDisposed = true
        
        // Remove method call handler first
        channel.setMethodCallHandler(nil)
        
        // Stop any ongoing recording if applicable
        if let cameraVC = viewController as? CameraViewController {
            cameraVC.stopRecording { _ in
                // Recording stopped, cleanup will continue
            }
        }
        
        // Cleanup viewController
        cleanupViewController()
    }
    
    private func cleanupViewController() {
        guard let vc = viewController else { return }
        
        // Ensure cleanup happens on main thread
        DispatchQueue.main.async {
            // Remove from parent view controller
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            
            // Clear the reference
            self.viewController = nil
        }
    }
    
    deinit {
        // Ensure disposal happens even if onDispose wasn't called
        performDisposal()
    }
    
    func sendToFlutter(_ method: String, arguments: Any?) {
        guard !isDisposed else { return }
        
        DispatchQueue.main.async {
            self.channel.invokeMethod(method, arguments: arguments)
        }
    }
    
    func onRecordingCompleted(recordingUUID: String) {
        guard !isDisposed else { return }
        
        let arguments: [String: String] = ["recordingUUID": recordingUUID]
        sendToFlutter("onRecordingCompleted", arguments: arguments)
    }
}
