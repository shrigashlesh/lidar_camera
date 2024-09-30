//
//  AVCameraCalibrationData+Extension.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//
import Foundation
import simd


// Serialize a 3x3 matrix to a List<List<Float>>
func serializeMatrix(_ matrix: simd_float3x3) -> [[Float]] {
    return [
        [matrix[0, 0], matrix[0, 1], matrix[0, 2]],
        [matrix[1, 0], matrix[1, 1], matrix[1, 2]],
        [matrix[2, 0], matrix[2, 1], matrix[2, 2]]
    ]
}

// Serialize a 4x4 matrix to a List<List<Float>>
func serializeMatrix(_ matrix: simd_float4x4) -> [[Float]] {
    return [
        [matrix[0, 0], matrix[0, 1], matrix[0, 2], matrix[0, 3]],
        [matrix[1, 0], matrix[1, 1], matrix[1, 2], matrix[1, 3]],
        [matrix[2, 0], matrix[2, 1], matrix[2, 2], matrix[2, 3]],
        [matrix[3, 0], matrix[3, 1], matrix[3, 2], matrix[3, 3]]
    ]
}

// Convert 3x3 matrix to Data for serialization
func serializeMatrixToData(_ matrix: simd_float3x3) -> Data {
    let matrixArray = serializeMatrix(matrix).flatMap { $0 }
    return Data(matrixArray.flatMap { withUnsafeBytes(of: $0) { Array($0) } })
}

// Convert 4x4 matrix to Data for serialization
func serializeMatrixToData(_ matrix: simd_float4x4) -> Data {
    let matrixArray = serializeMatrix(matrix).flatMap { $0 }
    return Data(matrixArray.flatMap { withUnsafeBytes(of: $0) { Array($0) } })
}

// Deserialize Data to 3x3 matrix
func deserialize3x3Matrix(data: Data) -> simd_float3x3? {
    var matrix = simd_float3x3()
    data.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) in
        guard let baseAddress = rawPointer.baseAddress?.assumingMemoryBound(to: Float.self) else { return }
        
        for i in 0..<3 {
            for j in 0..<3 {
                matrix[i, j] = baseAddress[i * 3 + j]
            }
        }
    }
    return matrix
}

// Deserialize Data to 4x4 matrix
func deserialize4x4Matrix(data: Data) -> simd_float4x4? {
    var matrix = simd_float4x4()
    data.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) in
        guard let baseAddress = rawPointer.baseAddress?.assumingMemoryBound(to: Float.self) else { return }
        
        for i in 0..<4 {
            for j in 0..<4 {
                matrix[i, j] = baseAddress[i * 4 + j]
            }
        }
    }
    return matrix
}
