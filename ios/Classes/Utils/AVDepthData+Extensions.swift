import AVFoundation
import CoreGraphics

extension AVDepthData {
    func asBytes() -> Data? {
        // Get the depth map as Float16
        let depthMap = self.depthDataMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            return nil
        }
        
        var depthValues = [Float16]()
        for row in 0..<height {
            let rowData = baseAddress.advanced(by: row * bytesPerRow).assumingMemoryBound(to: Float16.self)
            for col in 0..<width {
                let depthValue16 = rowData[col]
                depthValues.append(depthValue16)
            }
        }
        
        CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
        
        return Data(bytes: depthValues, count: depthValues.count * MemoryLayout<Float16>.size)
    }
}
