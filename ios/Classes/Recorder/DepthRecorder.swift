//
//  DepthRecorder.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 26/09/2024.
//

import CoreMedia
import CoreVideo
import Foundation

class DepthRecorder: Recorder {
    
    typealias T = CVPixelBuffer
    
    private let depthRecorderQueue = DispatchQueue(label: "depth recorder queue")
    
    private var count: Int32 = 0
    private var fileIO: BinaryFileIO? = nil
    private var recordingId: String? = nil
    
    func prepareForRecording(recordingId: String) {
        
        depthRecorderQueue.async {
            
            self.count = 0
            self.recordingId = recordingId
            self.fileIO = BinaryFileIO()
            if self.fileIO == nil {
                print("Unable to create file writer.")
                return
            }
            
        }
        
    }
    
    func update(_ buffer: CVPixelBuffer, timestamp: CMTime? = nil) {
        
        depthRecorderQueue.async {
            
            print("Saving depth frame \(self.count) ...")
            self.writePixelBufferToFile(buffer: buffer)
            self.count += 1
        }
        
    }
    
    func finishRecording(completion: ((String?, String?)-> Void)? = nil) {
        depthRecorderQueue.async {
            print("\(self.count) frames of depth saved.")
            if self.fileIO != nil {
                self.fileIO = nil
            }
        }
    }
    
    
    private func writePixelBufferToFile(buffer: CVPixelBuffer) {
        guard let recordingId = recordingId else {
            return
        }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(buffer)!
        let size = CVPixelBufferGetDataSize(buffer)
        let data = Data(bytesNoCopy: baseAddress, count: size, deallocator: .none)
        
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        do {
            let fileName = Helper.getDepthFileName(frameNumber: Int(count))
            try fileIO?.write(data, folder: recordingId, toDocumentNamed: fileName)
        } catch {
            print("Couldn't save depth at \(count)")
        }
    }
}
