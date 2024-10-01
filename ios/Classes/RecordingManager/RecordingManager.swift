//
//  RecordingManager.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 26/09/2024.
//

import Foundation

protocol RecordingManager {
    var isRecording: Bool { get }
    
    func getSession() -> NSObject
    
    func startRecording()
    func stopRecording(completion: ((String?) -> Void)?)
}
