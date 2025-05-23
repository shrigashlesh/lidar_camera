//
//  RGBRecorder.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 26/09/2024.
//

import AVFoundation
import Foundation
import Photos
import Flutter
import UIKit
import Metal
import CoreImage

class RGBRecorder: NSObject, Recorder {
    typealias T = CVPixelBuffer
    
    private let rgbRecorderQueue = DispatchQueue(label: "rgb recorder queue")
    private let streamProcessingQueue = DispatchQueue(label: "stream processing queue")
    
    // AVAssetWriter components for video recording
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var videoSettings: [String: Any]
    
    // Streaming components
    private var streamEventSink: FlutterEventSink?
    private var isStreamingEnabled = false
    
    // Frame throttling for streaming
    private var lastStreamFrameTime = CACurrentMediaTime()
    private let streamTargetFPS: Double = 10.0
    private var streamFrameInterval: CFTimeInterval { 1.0 / streamTargetFPS }
    
    // CIContext with Metal acceleration for streaming
    private lazy var ciContext: CIContext = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal device not available")
        }
        return CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .cacheIntermediates: false
        ])
    }()
    
    // Stream processing constants
    private struct StreamSettings {
        static let scale: CGFloat = 0.3
        static let jpegQuality: CGFloat = 0.35
        static let rotation: CGFloat = -.pi / 2
    }
    
    private var count: Int32 = 0
    private var location: CLLocation?
    
    init(videoSettings: [String: Any], location: CLLocation?) {
        self.videoSettings = videoSettings
        self.location = location
        super.init()
    }
    
    deinit {
        print("RGBRecorder deinitialized")
        stopStreaming()
    }
    
    // MARK: - Recording Methods
    
    func prepareForRecording(dirPath: String, recordingId: String, fileExtension: String = "mp4") {
        rgbRecorderQueue.async {
            
            self.count = 0
            let outputFilePath = (dirPath as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(fileExtension)!)
            let outputFileUrl = URL(fileURLWithPath: outputFilePath)
            guard let assetWriter = try? AVAssetWriter(url: outputFileUrl, fileType: .mp4) else {
                print("Failed to create AVAssetWriter.")
                return
            }
            
            let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.videoSettings)
            
            let assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: nil)
            
            assetWriterVideoInput.expectsMediaDataInRealTime = true
            assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: .pi/2)
            
            assetWriter.add(assetWriterVideoInput)
            
            // Audio settings
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000
            ]
            let assetAudioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            assetAudioWriterInput.expectsMediaDataInRealTime = true
            assetWriter.add(assetAudioWriterInput)
            
            self.assetWriter = assetWriter
            self.assetWriterVideoInput = assetWriterVideoInput
            self.assetWriterAudioInput = assetAudioWriterInput
            self.assetWriterInputPixelBufferAdaptor = assetWriterInputPixelBufferAdaptor
        }
    }
    
    func update(_ buffer: CVPixelBuffer, timestamp: CMTime?) {
        guard let timestamp = timestamp else {
            return
        }
        
        // Handle recording
        rgbRecorderQueue.async {
            self.recordFrame(buffer, timestamp: timestamp)
        }
        
        // Handle streaming if enabled
        if isStreamingEnabled {
            streamProcessingQueue.async {
                self.streamFrame(buffer)
            }
        }
    }
    
    private func recordFrame(_ buffer: CVPixelBuffer, timestamp: CMTime) {
        guard let assetWriter = self.assetWriter else {
            print("Error! assetWriter not initialized.")
            return
        }
        
        print("Saving video frame \(self.count) ...")
        
        if assetWriter.status == .unknown {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: timestamp)
            
            if let adaptor = self.assetWriterInputPixelBufferAdaptor {
                // In case adaptor not ready
                while !adaptor.assetWriterInput.isReadyForMoreMediaData {
                    print("Waiting for assetWriter...")
                    usleep(10)
                }
                adaptor.append(buffer, withPresentationTime: timestamp)
            }
        } else if assetWriter.status == .writing {
            if let adaptor = self.assetWriterInputPixelBufferAdaptor,
               adaptor.assetWriterInput.isReadyForMoreMediaData {
                adaptor.append(buffer, withPresentationTime: timestamp)
            }
        }
        
        self.count += 1
    }
    
    func updateAudioSample(_ buffer: CMSampleBuffer) {
        guard let audioWriterInput = assetWriterAudioInput else { return }
        if audioWriterInput.isReadyForMoreMediaData {
            audioWriterInput.append(buffer)
        }
    }
    
    func finishRecording() {
        rgbRecorderQueue.async {
            guard let assetWriter = self.assetWriter else {
                print("Asset writer not initialized!")
                return
            }
            
            assetWriter.finishWriting { [weak self] in
                guard let self = self else { return }
                
                if let videoURL = self.assetWriter?.outputURL {
                    print("RGB video to gallery at path: \(videoURL.path)")
                    self.assetWriter = nil
                }
            }
        }
    }
    
    // MARK: - Streaming Methods
    
    func startStreaming(eventSink: @escaping FlutterEventSink) {
        print("RGBRecorder: Starting frame streaming at \(streamTargetFPS) FPS")
        streamEventSink = eventSink
        isStreamingEnabled = true
    }
    
    func stopStreaming() {
        print("RGBRecorder: Stopping frame streaming")
        isStreamingEnabled = false
        streamEventSink = nil
    }
    
    private func streamFrame(_ buffer: CVPixelBuffer) {
        // Throttle frame streaming
        let now = CACurrentMediaTime()
        guard now - lastStreamFrameTime >= streamFrameInterval else { return }
        lastStreamFrameTime = now
        
        guard let eventSink = streamEventSink else { return }
        
        autoreleasepool {
            if let frameData = processFrameForStreaming(buffer) {
                DispatchQueue.main.async {
                    eventSink(frameData)
                }
            }
        }
    }
    
    private func processFrameForStreaming(_ pixelBuffer: CVPixelBuffer) -> [String: Any]? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .transformed(by: CGAffineTransform(scaleX: StreamSettings.scale, y: StreamSettings.scale)
            .rotated(by: StreamSettings.rotation))

        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage for streaming")
            return nil
        }

        guard let jpegData = UIImage(cgImage: cgImage).jpegData(compressionQuality: StreamSettings.jpegQuality) else {
            print("Failed to encode JPEG for streaming")
            return nil
        }

        return [
            "frameBytes": FlutterStandardTypedData(bytes: jpegData),
            "width": cgImage.width,
            "height": cgImage.height
        ]
    }
    
    // MARK: - Public Streaming Interface
    
    var isStreaming: Bool {
        return isStreamingEnabled
    }
    
    func setStreamEventSink(_ eventSink: FlutterEventSink?) {
        if let eventSink = eventSink {
            startStreaming(eventSink: eventSink)
        } else {
            stopStreaming()
        }
    }
}
