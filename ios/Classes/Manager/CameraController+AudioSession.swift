//
//  CameraController+AudioSession.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 19/09/2024.
//

import Foundation
import AVFoundation

extension CameraController{
    final func activateAudioSession() throws {
        
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
            
            if #available(iOS 13.0, *) {
                // allow system sounds (notifications, calls, music) to play while recording
                try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
            }
            audioCaptureSession?.startRunning()
        } catch let error as NSError {
            switch error.code {
            case 561_017_449:
                throw ConfigurationError.micInUse
            default:
                throw ConfigurationError.audioSessionFailedToActivate
            }
        }
    }
    
    final func deactivateAudioSession() {
        audioCaptureSession?.stopRunning()
    }
}
