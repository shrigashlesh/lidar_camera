import Foundation
import SwiftUI
import Combine
import simd
import AVFoundation

class CameraManager: ObservableObject, CaptureDataReceiver, CaptureTimeReceiver {
    
    @Published var recordedTime: CMTime
    var capturedData: CameraCapturedData
    @Published var isFilteringDepth: Bool {
        didSet {
            controller.isFilteringEnabled = isFilteringDepth
        }
    }
    @Published var dataAvailable = false
    @Published var isRecording: Bool {
        didSet {
            controller.isRecording = isRecording
        }
    }
    let controller: CameraController
    
    init() {
        // Initialize capturedData and controller
        capturedData = CameraCapturedData()
        recordedTime = .zero
        controller = CameraController()
        isRecording = false
        isFilteringDepth = false
        
        // Start streaming and set delegates
        controller.captureDelegate = self
        controller.timeReceiverDelegate = self
    }
    
    func outputVideoRecording() {
        isRecording = false
    }
    
    func startRecording() {
        isRecording = true
    }
    
    func onNewData(capturedData: CameraCapturedData) {
        DispatchQueue.main.async {
            // Update captured data for views
            self.capturedData.depth = capturedData.depth
            self.capturedData.colorY = capturedData.colorY
            self.capturedData.colorCbCr = capturedData.colorCbCr
            self.capturedData.cameraIntrinsics = capturedData.cameraIntrinsics
            self.capturedData.cameraReferenceDimensions = capturedData.cameraReferenceDimensions
            if !self.dataAvailable {
                self.dataAvailable = true
            }
        }
    }
    
    func onRecordingTimeUpdate(recordedTime: CMTime) {
        self.recordedTime = recordedTime
    }
    
    func cleanup() {
        print("CAMERA MANAGER CLEANUP")
        controller.captureDelegate = nil
        controller.timeReceiverDelegate = nil
    }
    
    deinit {
        cleanup()
    }
}
