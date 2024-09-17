//
//  DepthMap2DArray.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
import AVFoundation

extension AVDepthData {
    func extractDepthMap2D() -> [[Float]] {
        // Access the depth data map
        let depthDataMap = self.depthDataMap
        
        // Get the width and height of the depth data
        let width = CVPixelBufferGetWidth(depthDataMap)
        let height = CVPixelBufferGetHeight(depthDataMap)
        
        // Lock the pixel buffer to ensure data consistency
        CVPixelBufferLockBaseAddress(depthDataMap, .readOnly)
        
        // Access the base address of the depth data map
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthDataMap) else {
            CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
            return []
        }
        
        // Define an array to store depth data values as rows
        var depthValues2D: [[Float]] = []
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthDataMap)
        
        // Iterate through the depth data map to extract depth values
        for y in 0..<height {
            let rowPointer = baseAddress.advanced(by: y * bytesPerRow)
            let depthRow = rowPointer.assumingMemoryBound(to: Float32.self)
            
            // Create a row array for the current row
            var depthRowValues: [Float] = []
            
            for x in 0..<width {
                let depthValue = depthRow[x]
                depthRowValues.append(depthValue)
            }
            
            // Append the row to the 2D array
            depthValues2D.append(depthRowValues)
        }
        
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(depthDataMap, .readOnly)
        
        return depthValues2D
    }
}
