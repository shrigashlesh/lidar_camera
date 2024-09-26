import ARKit
import RealityKit
import UIKit

class CameraViewController: UIViewController {
    
    private var recordingManager: RecordingManager! = nil
    
    private var recordButton: RecordButton!
    
    var progressTimer: Timer?
    var progress: CGFloat = 0
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        initRecordingManagerAndPerformRecordingModeRelatedSetup()
        setupRecordButton()
    }
    
    @objc func updateProgress() {
        let maxDuration = CGFloat(5)
        progress += (CGFloat(0.05) / maxDuration)
        DispatchQueue.main.async { [weak self] in
            self?.recordButton.setProgress(self?.progress ?? 0)
        }
        
        if progress >= 1 {
            stopRecording()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func initRecordingManagerAndPerformRecordingModeRelatedSetup() {
        if #available(iOS 14.0, *) {
            recordingManager = ARCameraRecordingManager()
            let session = recordingManager.getSession() as! ARSession
            let arView = ARView()
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
    
    @objc func recordButtonTapped() {
        if recordingManager.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func setupRecordButton() {
        recordButton = RecordButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        recordButton.buttonColor = .red
        recordButton.progressColor = .red
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        
        view.addSubview(recordButton)
        
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            recordButton.widthAnchor.constraint(equalToConstant: 70),
            recordButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func startRecording() {
        progress = 0
        recordingManager.startRecording()
        
        DispatchQueue.main.async { [weak self] in
            self?.progressTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self!, selector: #selector(self!.updateProgress), userInfo: nil, repeats: true)
        }
    }
    
    func stopRecording() {
        progressTimer?.invalidate()
        progress = 0
        recordingManager.stopRecording()
    }
}
