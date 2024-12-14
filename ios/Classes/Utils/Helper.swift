//
//  Helper.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 26/09/2024.
//
import CoreLocation
import Foundation
import UIKit

struct Helper {
    
    static func getGpsLocation(locationManager: CLLocationManager) -> CLLocation? {
            
        // Use the instance method to get the authorization status
        let authorizationStatus = locationManager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            if let location = locationManager.location {
                return location
            }
        }
        return nil
    }

    
    static func getRecordingId() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        let dateString = dateFormatter.string(from: Date())
        
        let recordingId = dateString + "_" + UUID().uuidString
        
        return recordingId
    }
    
    static func getRecordingDataDirectoryPath(recordingId: String) -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        // create new directory for new recording
        let documentsDirectoryUrl = URL(string: documentsDirectory)!
        let recordingDataDirectoryUrl = documentsDirectoryUrl.appendingPathComponent(recordingId)
        if !FileManager.default.fileExists(atPath: recordingDataDirectoryUrl.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: recordingDataDirectoryUrl.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        
        let recordingDataDirectoryPath = recordingDataDirectoryUrl.absoluteString
        return recordingDataDirectoryPath
    }
}
