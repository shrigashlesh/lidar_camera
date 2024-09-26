//
//  ARCameraRecordingManager.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-11-17.
//  Copyright © 2020 jx16. All rights reserved.
//

import ARKit

@available(iOS 14.0, *)
class ARCameraRecordingManager: NSObject {
    
    private let sessionQueue = DispatchQueue(label: "ar camera recording queue")
    private let audioRecorderQueue = DispatchQueue(label: "audio recorder queue")
    
    private let session = ARSession()
    
    private let depthRecorder = DepthRecorder()
    // rgbRecorder will be initialized in configureSession
    private var rgbRecorder: RGBRecorder! = nil
    private let cameraInfoRecorder = CameraInfoRecorder()
    
    private var numFrames: Int = 0
    private var recordingId: String!
    var isRecording: Bool = false
    
    private let locationManager = CLLocationManager()
    private var gpsLocation: [Double] = []
    
    private var cameraIntrinsic: simd_float3x3?
    private var colorFrameResolution: [Int] = []
    private var depthFrameResolution: [Int] = []
    private var frequency: Int?
    
    override init() {
        super.init()
        
        locationManager.requestWhenInUseAuthorization()
        
        sessionQueue.async {
            self.configureSession()
        }
        setupAudioSession()
    }
    
    deinit {
        sessionQueue.sync {
            session.pause()
        }
        audioRecorderQueue.sync {
            deactivateAudioSession()
        }
    }
    
    
    // Capture session object to audio input/output.
    private(set) var audioCaptureSession: AVCaptureSession?
    // Output for audio
    private var audioDataOutput: AVCaptureAudioDataOutput?
    
    // Set up the capture session with audio inputs and outputs.
    private func setupAudioSession() {
        do {
            audioCaptureSession = AVCaptureSession()
            guard let audioCaptureSession = audioCaptureSession else {
                throw ConfigurationError.sessionUnavailable
            }
            audioCaptureSession.automaticallyConfiguresApplicationAudioSession = false
            audioCaptureSession.beginConfiguration()
            try setupAudioCaptureInput()
            try setupAudioCaptureOutput()
            audioCaptureSession.commitConfiguration()
        } catch {
            print("Unable to configure the audio session.")
        }
    }
    
    // Set up the camera input (LiDAR) for depth data, video, and audio.
    private func setupAudioCaptureInput() throws {
        guard let audioCaptureSession = audioCaptureSession else {
            throw ConfigurationError.sessionUnavailable
        }
        
        // Set up audio input (microphone)
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw ConfigurationError.micUnavailable
        }
        
        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
        audioCaptureSession.addInput(audioInput)  // Add the audio input to the capture session.
    }
    
    // Set up the outputs for video, depth data, and audio.
    private func setupAudioCaptureOutput() throws{
        guard let audioCaptureSession = audioCaptureSession else {
            throw ConfigurationError.sessionUnavailable
        }
        
        // Configure the audio data output.
        audioDataOutput = AVCaptureAudioDataOutput()
        guard let audioDataOutput = audioDataOutput else {return}
        audioDataOutput.setSampleBufferDelegate(self, queue: audioRecorderQueue)
        audioCaptureSession.addOutput(audioDataOutput)
        
    }
    private func find4by3VideoFormat() -> ARConfiguration.VideoFormat? {
        let availableFormats = ARWorldTrackingConfiguration.supportedVideoFormats
        for format in availableFormats {
            let resolution = format.imageResolution
            if resolution.width / 4 == resolution.height / 3 {
                print("Using video format: \(format)")
                return format
            }
        }
        return nil
    }
    
    private func configureSession() {
        
        let configuration = ARWorldTrackingConfiguration()

        // Enable only scene depth
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = [.sceneDepth]  // Set only scene depth
        }

        // Optionally, set the video format if available
        if let format = find4by3VideoFormat() {
            configuration.videoFormat = format
        } else {
            print("No 4:3 video format is available")
        }

        // Set session delegate and run the session
        session.delegate = self
        session.run(configuration)

        
        let videoFormat = configuration.videoFormat
        frequency = videoFormat.framesPerSecond
        let imageResolution = videoFormat.imageResolution
        colorFrameResolution = [Int(imageResolution.height), Int(imageResolution.width)]
        
        let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoHeightKey: NSNumber(value: colorFrameResolution[0]), AVVideoWidthKey: NSNumber(value: colorFrameResolution[1])]
        rgbRecorder = RGBRecorder(videoSettings: videoSettings)
    }
}

@available(iOS 14.0, *)
extension ARCameraRecordingManager: RecordingManager {
    
    func getSession() -> NSObject {
        return session
    }
    
    
    func startRecording() {
        do{
            try activateAudioSession()
        }catch{
            
        }
        sessionQueue.async { [self] in
            
            gpsLocation = Helper.getGpsLocation(locationManager: locationManager)
            
            numFrames = 0
            
            if let currentFrame = session.currentFrame {
                cameraIntrinsic = currentFrame.camera.intrinsics
                
                // get depth resolution
                if let depthData = currentFrame.sceneDepth {
                    
                    let depthMap: CVPixelBuffer = depthData.depthMap
                    let height = CVPixelBufferGetHeight(depthMap)
                    let width = CVPixelBufferGetWidth(depthMap)
                    
                    depthFrameResolution = [height, width]
                    
                } else {
                    print("Unable to get depth resolution.")
                }
                
            }
            
            print("pre1 count: \(numFrames)")
            
            recordingId = Helper.getRecordingId()
            
            depthRecorder.prepareForRecording(recordingId: recordingId)
            rgbRecorder.prepareForRecording(recordingId: recordingId)
            cameraInfoRecorder.prepareForRecording(recordingId: recordingId)
            
            isRecording = true
            
            print("pre2 count: \(numFrames)")
        }
        
    }
    
    func stopRecording() {
        deactivateAudioSession()
        sessionQueue.sync { [self] in
            
            print("post count: \(numFrames)")
            
            isRecording = false
            
            depthRecorder.finishRecording()
            rgbRecorder.finishRecording()
            cameraInfoRecorder.finishRecording()
            
        }
    }
    
}

@available(iOS 14.0, *)
extension ARCameraRecordingManager: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if !isRecording {
            return
        }
        
        guard let depthData = frame.sceneDepth else {
            print("Failed to acquire depth data.")
            return
        }
        
        let depthMap: CVPixelBuffer = depthData.depthMap
        let colorImage: CVPixelBuffer = frame.capturedImage
        
        let timestamp: CMTime = CMTime(seconds: frame.timestamp, preferredTimescale: 1_000_000_000)
        
        print("**** @Controller: depth \(numFrames) ****")
        depthRecorder.update(depthMap)
        
        print("**** @Controller: color \(numFrames) ****")
        rgbRecorder.update(colorImage, timestamp: timestamp)
        
        print("**** @Controller: camera info \(numFrames) ****")
        let currentCameraInfo = CameraInfo(
            intrinsics: frame.camera.intrinsics,
            transform: frame.camera.transform
        )
        cameraInfoRecorder.update(currentCameraInfo)
        
        numFrames += 1
    }
}

@available(iOS 14.0, *)
extension ARCameraRecordingManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !isRecording {
            return
        }
        if output == audioDataOutput {
            rgbRecorder.updateAudioSample(sampleBuffer)
        }
    }
    
    
    func activateAudioSession() throws {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                         mode: .videoRecording,
                                         options: [.mixWithOthers,
                                                   .allowBluetoothA2DP,
                                                   .defaultToSpeaker,
                                                   .allowAirPlay])
            
            if #available(iOS 14.5, *) {
                // prevents the audio session from being interrupted by a phone call
                try audioSession.setPrefersNoInterruptionsFromSystemAlerts(true)
            }
            
            
            // allow system sounds (notifications, calls, music) to play while recording
            try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
            audioRecorderQueue.async {
                self.audioCaptureSession?.startRunning()
            }
        } catch let error as NSError {
            switch error.code {
            case 561_017_449:
                throw ConfigurationError.micInUse
            default:
                throw ConfigurationError.audioSessionFailedToActivate
            }
        }
    }
    
    func deactivateAudioSession() {
        audioCaptureSession?.stopRunning()
    }
}
