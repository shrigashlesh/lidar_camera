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
    
    func finishRecording(completion: ((String?, String?) -> Void)? = nil) {
        
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
                        self.saveVideoToGallery(videoURL: videoURL, completion: completion)
                    }
                    self.assetWriter = nil
                }
            }
        }
    }
    
    func saveVideoToGallery(videoURL: URL, completion: ((String?, String?) -> Void)?) {
        // Request authorization if not already done
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Permission not granted to access photo library")
                completion?(nil, nil) // Return nil if permission is not granted
                return
            }

            // Begin the changes in the photo library
            var videoPlaceholder: PHObjectPlaceholder? = nil // Declare videoPlaceholder outside
            PHPhotoLibrary.shared().performChanges({
                // Check if the album already exists
                let albumName = "Fishtechy"
                var albumChangeRequest: PHAssetCollectionChangeRequest?
                var albumPlaceholder: PHObjectPlaceholder?

                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
                let albumFetch = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

                if let existingAlbum = albumFetch.firstObject {
                    // Album exists, fetch it
                    albumChangeRequest = PHAssetCollectionChangeRequest(for: existingAlbum)
                } else {
                    // Album does not exist, create it
                    albumChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                    albumPlaceholder = albumChangeRequest?.placeholderForCreatedAssetCollection
                }

                // Create a new asset creation request for the video
                let creationRequest = PHAssetCreationRequest.forAsset()
                videoPlaceholder = creationRequest.placeholderForCreatedAsset // Capture the placeholder
                creationRequest.addResource(with: .video, fileURL: videoURL, options: nil)
                creationRequest.creationDate = Date()

                // If we just created the album, get the created collection and add the video to it
                if let albumPlaceholder = albumPlaceholder {
                    let albumFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumPlaceholder.localIdentifier], options: nil)
                    if let newAlbum = albumFetchResult.firstObject {
                        albumChangeRequest = PHAssetCollectionChangeRequest(for: newAlbum)
                    }
                }

                // Add the video to the album
                if let albumChangeRequest = albumChangeRequest, let videoPlaceholder = videoPlaceholder {
                    let fastEnumeration = NSArray(array: [videoPlaceholder] as [PHObjectPlaceholder])
                    albumChangeRequest.addAssets(fastEnumeration)
                }

            }) { success, error in
                if success {
                    // Fetch the saved video by its placeholder's local identifier
                    guard let videoPlaceholder = videoPlaceholder else {
                        completion?(nil, nil) // Return nil if placeholder not found
                        return
                    }

                    let localIdentifier = videoPlaceholder.localIdentifier

                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [videoPlaceholder.localIdentifier], options: nil)
                    if let asset = fetchResult.firstObject {
                        // Get the file URL of the saved asset
                        self.getAssetFileURL(for: asset) { fileURL in
                            completion?(fileURL?.path, localIdentifier) // Return both file path and local identifier
                        }
                    } else {
                        completion?(nil, localIdentifier)
                    }
                } else {
                    if let error = error {
                        print("Error saving video: \(error.localizedDescription)")
                    }
                    completion?(nil, nil) // Return nil on failure
                }
            }
        }
    }

    // Helper function to get the file URL from PHAsset
    func getAssetFileURL(for asset: PHAsset, completion: @escaping (URL?) -> Void) {
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true // Allow fetching from iCloud if needed
        
        if let assetResource = PHAssetResource.assetResources(for: asset).first {
            let fileManager = FileManager.default
            let tempDir = NSTemporaryDirectory() // Temporary directory to store the file
            let filePath = (tempDir as NSString).appendingPathComponent(assetResource.originalFilename)
            let fileURL = URL(fileURLWithPath: filePath)
            
            if fileManager.fileExists(atPath: filePath) {
                completion(fileURL)
                return
            }
            
            PHAssetResourceManager.default().writeData(for: assetResource, toFile: fileURL, options: options) { error in
                if let error = error {
                    print("Error writing asset to file: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(fileURL)
                }
            }
        } else {
            completion(nil)
        }
    }

}
