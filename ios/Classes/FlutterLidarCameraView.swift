import Flutter
import UIKit

class FlutterLidarCameraView: NSObject, FlutterPlatformView, RecordingCompletionDelegate {
    func onRecordingCompleted(path: String) {
        // Create a dictionary with the recording path
        let arguments: [String: String] = ["recordingPath": path]
        sendToFlutter("onRecordingCompleted", arguments: arguments) // Pass the dictionary as arguments
    }
    
    private var _view: UIView
    private var viewController: UIViewController?
    let channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        channel = FlutterMethodChannel(name: "lidar_camera_\(viewId)", binaryMessenger: messenger)
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
        vc.recordingCompletionDelegate = self
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

     func onMethodCalled(_ call: FlutterMethodCall, _ result: FlutterResult) {
         _ = call.arguments as? [String: Any]
        switch call.method {
        case "dispose":
            onDispose(result)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func onDispose(_ result: FlutterResult) {
        // Ensure viewController is removed and cleaned up
        channel.setMethodCallHandler(nil)
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
}
