//
//  DepthMap2DArray.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
import AVFoundation
import tiff_ios
extension AVDepthData {
    func asBytes() -> Data? {
        let convertedDepthData = converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        let depthMap = convertedDepthData.depthDataMap
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
    
    func asTiff() -> TIFFImage? {
        let depthMap = depthDataMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        
        guard let rasters = TIFFRasters(width: Int32(width), andHeight: Int32(height), andSamplesPerPixel: 1, andSingleBitsPerSample: 32) else {
            CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        for y in 0..<height {
            let pixelBytes = baseAddress.advanced(by: y * bytesPerRow)
            let pixelBuffer = UnsafeBufferPointer<Float>(start: pixelBytes.assumingMemoryBound(to: Float.self), count: width)
            for x in 0..<width {
                rasters.setFirstPixelSampleAtX(Int32(x), andY: Int32(y), withValue: NSDecimalNumber(value: pixelBuffer[x]))
            }
        }
        
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
        
        let rowsPerStrip = UInt16(rasters.calculateRowsPerStrip(withPlanarConfiguration: Int32(TIFF_PLANAR_CONFIGURATION_CHUNKY)))
        
        guard let directory = TIFFFileDirectory() else {
            return nil
        }
        directory.setImageWidth(UInt16(width))
        directory.setImageHeight(UInt16(height))
        directory.setBitsPerSampleAsSingleValue(32)
        directory.setCompression(UInt16(TIFF_COMPRESSION_NO))
        directory.setPhotometricInterpretation(UInt16(TIFF_PHOTOMETRIC_INTERPRETATION_BLACK_IS_ZERO))
        directory.setSamplesPerPixel(1)
        directory.setRowsPerStrip(rowsPerStrip)
        directory.setPlanarConfiguration(UInt16(TIFF_PLANAR_CONFIGURATION_CHUNKY))
        directory.setSampleFormatAsSingleValue(UInt16(TIFF_SAMPLE_FORMAT_FLOAT))
        directory.writeRasters = rasters
        
        guard let tiffImage = TIFFImage() else {
            return nil
        }
        tiffImage.addFileDirectory(directory)
        return tiffImage
    }

}
