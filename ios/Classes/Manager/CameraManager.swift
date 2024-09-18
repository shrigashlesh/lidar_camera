/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that connects the camera controller and the views.
*/

import Foundation
import SwiftUI
import Combine
import simd
import AVFoundation

class CameraManager: ObservableObject, CaptureDataReceiver, CaptureTimeReceiver {

    @Published var recordedTime : CMTime

    var capturedData: CameraCapturedData
    @Published var isFilteringDepth: Bool {
        didSet {
            controller.isFilteringEnabled = isFilteringDepth
        }
    }
    @Published var orientation = UIDevice.current.orientation
    @Published var processingCapturedResult = false
    @Published var dataAvailable = false
    @Published var isRecording: Bool {
        didSet {
            controller.isRecording = isRecording
        }
    }
    let controller: CameraController
    var cancellables = Set<AnyCancellable>()
    var session: AVCaptureSession { controller.captureSession }
    
    init() {
        // Create an object to store the captured data for the views to present.
        capturedData = CameraCapturedData()
        recordedTime = .zero
        controller = CameraController()
        isRecording = false
        controller.startStream()
        isFilteringDepth = false
        controller.captureDelegate = self
        controller.timeReceiverDelegate = self
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification).sink { _ in
            self.orientation = UIDevice.current.orientation
        }.store(in: &cancellables)
    }
    
    func outputVideoRecording() {
        isRecording = false
    }
    
    
    func startRecording() {
        isRecording = true
    }
    
    
    func onNewData(capturedData: CameraCapturedData) {
        DispatchQueue.main.async {
            if !self.processingCapturedResult {
                // Because the views hold a reference to `capturedData`, the app updates each texture separately.
                self.capturedData.depth = capturedData.depth
                self.capturedData.colorY = capturedData.colorY
                self.capturedData.colorCbCr = capturedData.colorCbCr
                self.capturedData.cameraIntrinsics = capturedData.cameraIntrinsics
                self.capturedData.cameraReferenceDimensions = capturedData.cameraReferenceDimensions
                if self.dataAvailable == false {
                    self.dataAvailable = true
                }
            }
        }
    }
    
    func onRecordingTimeUpdate(recordedTime: CMTime) {
        self.recordedTime = recordedTime
    }
}
