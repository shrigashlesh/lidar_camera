//
//  Helper.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-02-10.
//  Copyright © 2020 jx16. All rights reserved.
//

import CommonCrypto
import CoreLocation
import Foundation
import UIKit

struct Helper {
    
    // this assume gps authorization has been done previously
    static func getGpsLocation(locationManager: CLLocationManager) -> [Double] {
        
        var gpsLocation: [Double] = []
        
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways) {
            if let coordinate = locationManager.location?.coordinate {
                gpsLocation = [coordinate.latitude, coordinate.longitude]
            }
        }
        
        return gpsLocation
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
