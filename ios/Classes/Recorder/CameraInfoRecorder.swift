//
//  CameraInfoRecorder.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 26/09/2024.
//

import CoreMedia
import Foundation
import simd

class CameraInfo {
    
    private var intrinsics: simd_float3x3
    private var transform: simd_float4x4
    
    internal init(intrinsics: simd_float3x3, transform: simd_float4x4) {
        self.intrinsics = intrinsics
        self.transform = transform
    }
    
    func getIntrinsicData() -> Data {
       return serializeMatrixToData(intrinsics)
    }
    
    func getTranformData() -> Data {
       return serializeMatrixToData(transform)
    }
}

class CameraInfoRecorder: Recorder {
    
    typealias T = CameraInfo
    
    private let cameraInfoRecorderQueue = DispatchQueue(label: "camera info recorder queue")
    
    private var count: Int32 = 0
    private var fileIO: BinaryFileIO? = nil
    private var recordingId: String? = nil
    
    func prepareForRecording(recordingId: String) {
        
        cameraInfoRecorderQueue.async {
            
            self.count = 0
            self.recordingId = recordingId
            self.fileIO = BinaryFileIO()
            if self.fileIO == nil {
                print("Unable to create file writer.")
                return
            }
            
        }
        
    }
    
    func update(_ cameraInfo: CameraInfo, timestamp: CMTime? = nil) {
        cameraInfoRecorderQueue.async {
            print("Saving camera info \(self.count) ...")
            self.writeCameraInfoToFile(cameraInfo: cameraInfo)
            self.count += 1
        }
    }
    
    private func writeCameraInfoToFile(cameraInfo: CameraInfo) {
        guard let recordingId = recordingId else {
            return
        }
        
        let cameraIntrinsicData = cameraInfo.getIntrinsicData()
        let cameraTransformData = cameraInfo.getTranformData()
        do {
            let intrinicFileName = Helper.getIntrinsicFileName(frameNumber: Int(self.count))
            let transformFileName = Helper.getTransformFileName(frameNumber: Int(self.count))
            try self.fileIO?.write(cameraIntrinsicData, folder: recordingId, toDocumentNamed: intrinicFileName)
            try fileIO?.write(cameraTransformData, folder: recordingId, toDocumentNamed: transformFileName)
        } catch {
            print("Couldn't save full camera info \(self.count)")
        }
       
    }
    
    func finishRecording(completion: ((String?, String?) -> Void)? = nil) {
        cameraInfoRecorderQueue.async {
            print("\(self.count) frames of camera info saved.")
            if self.fileIO != nil {
                self.fileIO = nil
            }
        }
    }
}
