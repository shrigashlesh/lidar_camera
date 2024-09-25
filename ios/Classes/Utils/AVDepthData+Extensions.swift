//
//  DepthMap2DArray.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
import AVFoundation
import ARKit

extension AVDepthData {
    func asBytes() -> Data? {
        let depthMap = depthDataMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        var depthValues = [Float]()
        for y in 0..<height {
            let pixelBytes = baseAddress.advanced(by: y * bytesPerRow)
            let pixelBuffer = UnsafeBufferPointer<Float>(start: pixelBytes.assumingMemoryBound(to: Float.self), count: width)
            for x in 0..<width {
                depthValues.append(pixelBuffer[x])
            }
        }
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        return Data(depthValues.flatMap { withUnsafeBytes(of: $0) { Array($0) } })
    }
}
extension ARDepthData {
    func asBytes() -> Data? {
        let depthMap = depthMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        var depthValues = [Float]()
        for y in 0..<height {
            let pixelBytes = baseAddress.advanced(by: y * bytesPerRow)
            let pixelBuffer = UnsafeBufferPointer<Float>(start: pixelBytes.assumingMemoryBound(to: Float.self), count: width)
            for x in 0..<width {
                depthValues.append(pixelBuffer[x])
            }
        }
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        return Data(depthValues.flatMap { withUnsafeBytes(of: $0) { Array($0) } })
    }
}
