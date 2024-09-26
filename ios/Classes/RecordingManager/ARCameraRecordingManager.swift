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
    
    private let session = ARSession()
    
    private let depthRecorder = DepthRecorder()
    // rgbRecorder will be initialized in configureSession
    private var rgbRecorder: RGBRecorder! = nil
    private let cameraInfoRecorder = CameraInfoRecorder()
    
    private var numFrames: Int = 0
    private var dirUrl: URL!
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
    }
    
    deinit {
        sessionQueue.sync {
            session.pause()
        }
    }
    
    private func configureSession() {
        session.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
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

