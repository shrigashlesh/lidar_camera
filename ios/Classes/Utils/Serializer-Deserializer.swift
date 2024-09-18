//
//  AVCameraCalibrationData+Extension.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
import simd

// Helper function to serialize an array of Float
func serializeArray(_ array: simd_float3) -> [Float] {
    return [array.x, array.y, array.z]
}

// Serialize a 3x3 matrix to an array of Float
func serializeMatrix(_ matrix: simd_float3x3) -> [Float] {
    let matrixArray = [matrix.columns.0, matrix.columns.1, matrix.columns.2].flatMap { serializeArray($0) }
    return matrixArray
}

// Serialize a 4x3 matrix to an array of Float
func serializeMatrix(_ matrix: simd_float4x3) -> [Float] {
    let matrixArray = [matrix.columns.0, matrix.columns.1, matrix.columns.2, matrix.columns.3].flatMap { serializeArray($0) }
    return matrixArray
}

// Convert 3x3 matrix to Data
func serializeMatrixToData(_ matrix: simd_float3x3) -> Data {
    let matrixArray = serializeMatrix(matrix)
    return Data(matrixArray.flatMap { withUnsafeBytes(of: $0) { Array($0) } })
}

// Convert 4x3 matrix to Data
func serializeMatrixToData(_ matrix: simd_float4x3) -> Data {
    let matrixArray = serializeMatrix(matrix)
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

// Deserialize Data to 4x3 matrix
func deserialize4x3Matrix(data: Data) -> simd_float4x3? {
    var matrix = simd_float4x3()
    data.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) in
        guard let baseAddress = rawPointer.baseAddress?.assumingMemoryBound(to: Float.self) else { return }
        
        for i in 0..<4 {
            for j in 0..<3 {
                matrix[i, j] = baseAddress[i * 3 + j]
            }
        }
    }
    return matrix
}
