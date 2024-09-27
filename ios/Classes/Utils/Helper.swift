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
        //        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ssZ"
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        let dateString = dateFormatter.string(from: Date())
        
        let recordingId = dateString + "_" + UUID().uuidString
        
        return recordingId
    }
    
    private static func frameSuffix(frameNumber: Int) -> String {
        let frameNumberSuffix = String(format: "%04d", frameNumber);
        return frameNumberSuffix
    }
    
    static func getDepthFileName(frameNumber: Int) -> String {
        let frameNumberSuffix = frameSuffix(frameNumber:frameNumber)
        return "depth_\(frameNumberSuffix)"
    }
    
    static func getIntrinsicFileName(frameNumber: Int) -> String {
        let frameNumberSuffix = frameSuffix(frameNumber:frameNumber)
        return "intrinsic_\(frameNumberSuffix)"
    }
    
    static func getTransformFileName(frameNumber: Int) -> String {
        let frameNumberSuffix = frameSuffix(frameNumber:frameNumber)
        return "transform_\(frameNumberSuffix)"
    }
}
