import Flutter
import UIKit

// Protocol for camera initialization callback
protocol CameraInitializationDelegate: AnyObject {
    func cameraDidInitialize(success: Bool)
}

class FlutterLidarCameraView: NSObject, FlutterPlatformView {

    private var _view: UIView
    private weak var viewController: CameraViewController?
    private let channel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel?
    private var pendingEventSink: FlutterEventSink?
    private var isViewCreated = false
    private var isInitialized = false
    
    // Loading state management
    private var loadingIndicator: UIActivityIndicatorView?
    private var isWaitingForViewController = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self._view = UIView()
        self.channel = FlutterMethodChannel(name: "lidar/view_\(viewId)", binaryMessenger: messenger)
        super.init()
        self.channel.setMethodCallHandler(handleMethodCall)

        self.eventChannel = FlutterEventChannel(name: "lidar/stream", binaryMessenger: messenger)
        self.eventChannel?.setStreamHandler(self)

        // Show loading and attempt to create view
        showLoadingState()
        attemptToCreateNativeView()
    }

    func view() -> UIView {
        return _view
    }
    
    private func showLoadingState() {
        // Activity indicator
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
                
        // Add container to main view
        _view.addSubview(indicator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
        
        ])
        // Store references
        self.loadingIndicator = indicator
    }
    
    private func hideLoadingState() {
        loadingIndicator?.stopAnimating()
        loadingIndicator = nil
    }
    

    private func attemptToCreateNativeView() {
        guard !isViewCreated && !isWaitingForViewController else { return }
        
        isWaitingForViewController = true
        
        // Use the executeWhenViewControllerReady method
        UIApplication.shared.executeWhenViewControllerReady(
            maxRetries: 15,
            delay: 0.1
        ) {
            DispatchQueue.main.async {
                self.isWaitingForViewController = false
                self.createNativeView()
            }
        }
    }

    private func createNativeView() {
        guard !isViewCreated else { return }
        isViewCreated = true
                
        guard let topController = UIApplication.shared.keyWindowPresentedController else {
            print("Failed to get root view controller after retries")
            self.sendToFlutter("onError", arguments: "Failed to get view controller")
            return
        }
        
        let vc = CameraViewController()
        // Set up the delegate before adding as child
        vc.initializationDelegate = self
        self.viewController = vc

        // Properly add as child view controller
        topController.addChild(vc)
        
        guard let cameraView = vc.view else {
            print("Failed to get camera view")
            vc.removeFromParent()
            self.sendToFlutter("onError", arguments: "Failed to get camera view")
            return
        }
        
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(cameraView)

        NSLayoutConstraint.activate([
            cameraView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            cameraView.topAnchor.constraint(equalTo: _view.topAnchor),
            cameraView.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])

        vc.didMove(toParent: topController)
    }
    
    @objc private func retryInitialization() {
        // Reset state
        isViewCreated = false
        isInitialized = false
        isWaitingForViewController = false
        
        // Clear existing view controller
        if let vc = viewController {
            vc.initializationDelegate = nil
            vc.cleanup()
            vc.willMove(toParent: nil)
            vc.view?.removeFromSuperview()
            vc.removeFromParent()
            viewController = nil
        }
        
        // Reset loading state
        loadingIndicator?.isHidden = false
        loadingIndicator?.color = .white
        loadingIndicator?.startAnimating()
        
        // Retry
        attemptToCreateNativeView()
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
            DispatchQueue.main.async {
                success ? result(success) : result(FlutterError(code: "RECORDING_ERROR", message: "Failed to start recording", details: nil))
            }
        }
    }

    private func stopRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController else {
            result(FlutterError(code: "UNAVAILABLE", message: "Camera controller not available", details: nil))
            return
        }

        cameraVC.stopRecording { recordingUUID in
            DispatchQueue.main.async {
                if let uuid = recordingUUID {
                    result(["recordingUUID": uuid])
                } else {
                    result(FlutterError(code: "STOP_RECORDING_ERROR", message: "Failed to stop recording", details: nil))
                }
            }
        }
    }

    private func startLidarRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController else {
            result(FlutterError(code: "UNAVAILABLE", message: "Camera controller not available", details: nil))
            return
        }

        cameraVC.startLidarRecording { lidarDataStartMs in
            DispatchQueue.main.async {
                if let ms = lidarDataStartMs {
                    result(["lidarDataStartMs": ms])
                } else {
                    result(FlutterError(code: "LIDAR_RECORDING_ERROR", message: "Failed to start lidar recording", details: nil))
                }
            }
        }
    }

    private func stopLidarRecording(_ result: @escaping FlutterResult) {
        guard let cameraVC = viewController else {
            result(FlutterError(code: "UNAVAILABLE", message: "Camera controller not available", details: nil))
            return
        }

        cameraVC.stopLidarRecording { success in
            DispatchQueue.main.async {
                success ? result(success) : result(FlutterError(code: "STOP_LIDAR_RECORDING_ERROR", message: "Failed to stop lidar recording", details: nil))
            }
        }
    }

    private func onDispose(_ result: FlutterResult) {
        performDisposal()
        result(nil)
    }

    private func performDisposal() {
        channel.setMethodCallHandler(nil)
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        pendingEventSink = nil

        if let vc = viewController {
            vc.initializationDelegate = nil
            vc.cleanup()
            vc.willMove(toParent: nil)
            vc.view?.removeFromSuperview()
            vc.removeFromParent()
            viewController = nil
        }

        _view.subviews.forEach { $0.removeFromSuperview() }
        hideLoadingState()
        isViewCreated = false
        isInitialized = false
        isWaitingForViewController = false
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

// MARK: - CameraInitializationDelegate
extension FlutterLidarCameraView: CameraInitializationDelegate {
    func cameraDidInitialize(success: Bool) {
        DispatchQueue.main.async {
            self.isInitialized = success
            
            if success {
                // Hide loading state when successfully initialized
                self.hideLoadingState()
                
                // Apply pending event sink now that recording manager is ready
                if let eventSink = self.pendingEventSink,
                   let recordingManager = self.viewController?.recordingManager {
                    recordingManager.rgbStreamer.setEventSink(eventSink)
                    self.pendingEventSink = nil
                }
                self.sendToFlutter("onViewInitialized", arguments: nil)
            } else {
                self.sendToFlutter("onError", arguments: "Failed to initialize camera")
            }
        }
    }
}

// MARK: - FlutterStreamHandler
extension FlutterLidarCameraView: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let cameraVC = viewController,
           let recordingManager = cameraVC.recordingManager,
           isInitialized {
            recordingManager.rgbStreamer.setEventSink(events)
        } else {
            // Store for later when initialization completes
            pendingEventSink = events
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let vc = viewController {
            vc.recordingManager?.rgbStreamer.setEventSink(nil)
        }
        pendingEventSink = nil
        return nil
    }
}
