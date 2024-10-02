import ARKit
import RealityKit
import UIKit

protocol RecordingCompletionDelegate: AnyObject{
    func onRecordingCompleted(path: String, identifier: String)
}

class CameraViewController: UIViewController {
    
    private var recordingManager: ARCameraRecordingManager! = nil
    private var recordButton: RecordButton!
    private var recordedTimeView: RecordedTimeView! // Add RecordedTimeView
    
    var progress: CGFloat = 0.0
    let maxDuration: TimeInterval = 5.0 // Maximum recording duration in seconds
    var startTime: TimeInterval = 0.0 // To track the start time
    var timer: Timer? // Timer for regular updates
    weak var recordingCompletionDelegate: RecordingCompletionDelegate?
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
        setupRecordedTimeView() // Setup the RecordedTimeView
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
    
    private func setupRecordedTimeView() {
        recordedTimeView = RecordedTimeView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        recordedTimeView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(recordedTimeView)
        
        NSLayoutConstraint.activate([
            recordedTimeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            recordedTimeView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        recordedTimeView.updateTime(positionalTime: CMTime.zero.positionalTime, isRecording: false) // Initial state
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
        startTime = Date().timeIntervalSince1970 // Record the start time
        recordingManager.startRecording()
        
        // Start a timer for smooth progress updates
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    
    func stopRecording() {
        recordingManager.stopRecording(completion: {path, identifier in
            guard let path = path, let identifier = identifier else {
                return
            }
            self.recordingCompletionDelegate?.onRecordingCompleted(path: path, identifier: identifier)
        })
        timer?.invalidate() // Invalidate the timer
        // Update RecordedTimeView to show not recording state
        recordedTimeView.updateTime(positionalTime: CMTime.zero.positionalTime, isRecording: false)
    }
    
    @objc private func updateProgress() {
        let elapsedTime = Date().timeIntervalSince1970 - startTime // Calculate elapsed time
        if elapsedTime < maxDuration {
            progress = CGFloat(elapsedTime / maxDuration)
            recordButton.setProgress(progress)
            recordedTimeView.updateTime(positionalTime: CMTime(seconds: elapsedTime, preferredTimescale: 1_000_000_000).positionalTime, isRecording: true) // Update positional time
        } else {
            progress = 1.0
            recordButton.setProgress(progress)
            stopRecording() // Stop recording if max duration is reached
        }
    }
}
