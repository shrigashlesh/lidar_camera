//
//  DepthMap2DArray.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
import AVFoundation

extension AVDepthData {
    func asBytes() -> Data? {
        let depthMap = depthDataMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            return nil
        }

        // Prepare a Data object to store the depth map with width and height
        var depthData = Data()

        // Convert width and height to Int32 and append to the data (first 8 bytes)
        var widthInt32 = Int32(width)
        var heightInt32 = Int32(height)
        depthData.append(Data(bytes: &widthInt32, count: MemoryLayout<Int32>.size))
        depthData.append(Data(bytes: &heightInt32, count: MemoryLayout<Int32>.size))

        // Traverse each row, accessing the float values directly
        for y in 0..<height {
            let pixelBytes = baseAddress.advanced(by: y * bytesPerRow)
            let pixelBuffer = UnsafeBufferPointer<Float>(
                start: pixelBytes.assumingMemoryBound(to: Float.self),
                count: width
            )

            // Append each pixel's float value to the data buffer
            for depthValue in pixelBuffer {
                var value = depthValue
                let bytes = withUnsafeBytes(of: &value) { Data($0) }
                depthData.append(bytes)
            }
        }

        CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
        return depthData
    }


}
