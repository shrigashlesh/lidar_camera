import ARKit
import RealityKit
import UIKit
import Flutter

class CameraViewController: UIViewController, FlutterStreamHandler {
    
    private var recordingManager: ARCameraRecordingManager?
    
    var arView: ARView?
    private weak var messenger: FlutterBinaryMessenger?
    private var eventChannel: FlutterEventChannel?
    
    init(messenger: FlutterBinaryMessenger?) {
        self.messenger = messenger
        super.init(nibName: nil, bundle: nil)
        setupEventChannel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEventChannel() {
        guard let messenger = messenger else { return }
        eventChannel = FlutterEventChannel(name: "lidar/stream", binaryMessenger: messenger)
        eventChannel?.setStreamHandler(self)
    }
    
    // MARK: - FlutterStreamHandler
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        recordingManager?.rgbStreamer.startStreaming(eventSink: events)
        // You can start sending events now
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
    
    func cleanup() {
        recordingManager = nil
        arView?.scene.anchors.removeAll()
        arView?.removeFromSuperview()
        arView = nil
        eventChannel?.setStreamHandler(nil)  // Break retain cycle
        eventChannel = nil
        messenger = nil
    }

    
    deinit {
        cleanup()
        print("CameraViewController deinitialized")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        initRecordingManagerAndPerformRecordingModeRelatedSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func initRecordingManagerAndPerformRecordingModeRelatedSetup() {
        if #available(iOS 14.0, *) {
            recordingManager = ARCameraRecordingManager()
            let session = recordingManager!.getSession() as! ARSession
            arView = ARView()
            guard let arView = arView else {
                print("Error: arView is not initialized yet")
                return
            }
            
            arView.session = session
            setupPreviewView(previewView: arView)
        } else {
            print("AR camera only available for iOS 14.0 or newer.")
        }
    }
    
    private func setupPreviewView(previewView: UIView) {
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        
        let aspectRatioConstraint = previewView.widthAnchor.constraint(equalTo: previewView.heightAnchor, multiplier: 3.0/4.0)
        aspectRatioConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            previewView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        previewView.backgroundColor = .black
    }
    
    func startRecording(completion: ((Bool) -> Void)) {
        guard let recordingManager = recordingManager else {
            return
        }
        recordingManager.startRecording()
        completion(true)
    }
    
    func stopRecording(completion: RecordingManagerCompletion?) {
        guard let recordingManager = recordingManager else{
            return
        }
        recordingManager.stopRecording(completion: { recordingUUID in
            guard let recordingUUID = recordingUUID else {
                return
            }
            completion?(recordingUUID)
        })
    }
    
    func startLidarRecording(completion: DepthDataStartCompletion?) {
        guard let recordingManager = recordingManager else {
            return
        }
        recordingManager.startLidarRecording(completion: completion)
    }
    
    func stopLidarRecording(completion: ((Bool) -> Void)) {
        guard let recordingManager = recordingManager else{
            return
        }
        recordingManager.stopLidarRecording()
        completion(true)

    }
}
