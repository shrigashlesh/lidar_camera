//
//  AVCameraCalibrationData+Extension.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
import AVFoundation

extension AVCameraCalibrationData {
    func extractIntrinsicMatrix2D() -> [[Float]] {
        let intrinsicMatrix = self.intrinsicMatrix
        
        return [
            [intrinsicMatrix.columns.0.x, intrinsicMatrix.columns.0.y, intrinsicMatrix.columns.0.z],
            [intrinsicMatrix.columns.1.x, intrinsicMatrix.columns.1.y, intrinsicMatrix.columns.1.z],
            [intrinsicMatrix.columns.2.x, intrinsicMatrix.columns.2.y, intrinsicMatrix.columns.2.z]
        ]
    }
    
    func extractViewTransform2D() -> [[Float]] {
            let extrinsicMatrix = self.extrinsicMatrix
            
            return [
                [extrinsicMatrix.columns.0.x, extrinsicMatrix.columns.0.y, extrinsicMatrix.columns.0.z],
                [extrinsicMatrix.columns.1.x, extrinsicMatrix.columns.1.y, extrinsicMatrix.columns.1.z],
                [extrinsicMatrix.columns.2.x, extrinsicMatrix.columns.2.y, extrinsicMatrix.columns.2.z],
                [extrinsicMatrix.columns.3.x, extrinsicMatrix.columns.3.y, extrinsicMatrix.columns.3.z]
            ]
        }
}
