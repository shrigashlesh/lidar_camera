import ARKit
import RealityKit
import UIKit

class CameraViewController: UIViewController {
    
    private var recordingManager: ARCameraRecordingManager?
        
    private var arView: ARView?

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        recordingManager = nil
        arView?.scene.anchors.removeAll()
        arView = nil
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
            arView?.session = session
            setupPreviewView(previewView: arView!)
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
    
    
    func startRecording(completion: ((Bool) -> Void)? = nil) {
    guard let recordingManager = recordingManager else {
        return
    }
        recordingManager.startRecording()
        completion?(true)
    }
    
    func stopRecording(completion: ((Bool, String?, String?) -> Void)? = nil) {
    guard let recordingManager = recordingManager else{
        return
    }
    recordingManager.stopRecording(completion: { [weak self] path, identifier in
            guard let self = self, let path = path, let identifier = identifier else {
                return
            }
            completion?(true, path, identifier)
        })
    }
}
