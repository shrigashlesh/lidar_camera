//
//  DepthConversionData.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation

public struct DepthConversionData: Codable {
    let depth: [[Float]]
    let cameraIntrinsic: [[Float]]
    let viewTransform: [[Float]]
}

public struct DepthConversionDataContainer: Codable {
    var timestampedData: [String: DepthConversionData] = [:]
}
