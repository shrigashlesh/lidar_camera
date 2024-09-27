//
//  RGBRecorder.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 26/09/2024.
//

import AVFoundation
import Foundation
import Photos

class RGBRecorder: NSObject, Recorder {
    typealias T = CVPixelBuffer
    
    private let rgbRecorderQueue = DispatchQueue(label: "rgb recorder queue")
    
    // AVAssetWriter components for video recording.
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var videoSettings: [String: Any]
    
    private var count: Int32 = 0
    private var location: CLLocation? = nil
    init(videoSettings: [String: Any], location: CLLocation?) {
        self.videoSettings = videoSettings
        self.location = location
    }
    
    func prepareForRecording(recordingId: String) {
        rgbRecorderQueue.async {
            
            self.count = 0
            let outputFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(recordingId).mp4")
            
            guard let assetWriter = try? AVAssetWriter(url: outputFileUrl, fileType: .mp4) else {
                print("Failed to create AVAssetWriter.")
                return
            }
            
            
            let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.videoSettings)
            
            let assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: nil)
            
            assetWriterVideoInput.expectsMediaDataInRealTime = true
            assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: .pi/2)
            
            assetWriter.add(assetWriterVideoInput)
            
            
            // Audio settings.
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
        
        rgbRecorderQueue.async {
            
            guard let assetWriter = self.assetWriter else {
                print("Error! assetWriter not initialized.")
                return
            }
            
            print("Saving video frame \(self.count) ...")
            
            if assetWriter.status == .unknown {
                
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: timestamp)
                
                if let adaptor = self.assetWriterInputPixelBufferAdaptor {
                    
                    // incase adaptor not ready
                    // not sure if this is necessary
                    while !adaptor.assetWriterInput.isReadyForMoreMediaData {
                        print("Waiting for assetWriter...")
                        usleep(10)
                    }
                    
                    adaptor.append(buffer, withPresentationTime: timestamp)
                }
                
            } else if assetWriter.status == .writing {
                if let adaptor = self.assetWriterInputPixelBufferAdaptor, adaptor.assetWriterInput.isReadyForMoreMediaData {
                    adaptor.append(buffer, withPresentationTime: timestamp)
                }
            }
            
            self.count += 1
        }
    }
    
    func updateAudioSample(_ buffer: CMSampleBuffer){
        guard let audioWriterInput = assetWriterAudioInput else { return }
        if audioWriterInput.isReadyForMoreMediaData {
            audioWriterInput.append(buffer)
        }
    }
    
    func finishRecording() {
        
        rgbRecorderQueue.async {
            
            guard let assetWriter = self.assetWriter else {
                print("Error!")
                return
            }
            
            assetWriter.finishWriting { [weak self] in
                guard let self = self else { return }
                
                if let videoURL = self.assetWriter?.outputURL {
                    
                    DispatchQueue.main.async { [self] in
                        print("Saving video to gallery at path: \(videoURL.path)")
                        self.saveVideoToGallery(videoURL: videoURL)
                    }
                    self.assetWriter = nil
                }
            }
        }
    }
    
    
    
    func saveVideoToGallery(videoURL: URL) {
        // Request authorization if not already done
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Permission not granted to access photo library")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                // Create a new asset creation request
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL: videoURL, options: nil)
                creationRequest.creationDate = Date()
                creationRequest.location = self.location
                
            }) { success, error in
                if success {
                    print("Video saved successfully to user photo library.")
                } else if let error = error {
                    print("Error saving video: \(error.localizedDescription)")
                }
            }
        }
        
    }
}
