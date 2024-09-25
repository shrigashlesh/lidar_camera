//
//  DepthConversionData.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
import simd
public struct DepthConversionData {
    let depth: Data
    let cameraIntrinsic: Data
    let viewTransform: Data
    let timeStamp: Float64
}
public struct ARDepthConversionData {
    let depth: Data
    let cameraIntrinsic: simd_float3x3
    let viewTransform: simd_float4x4
    let timeStamp: Float64
}
