//
//  DepthConversionData.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation

public struct DepthConversionData {
    let depth: Data
    let cameraIntrinsic: Data
    let viewTransform: Data
    let timeStamp: Float64
}
