//
//  LidarCamera.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 16/09/2024.
//

import SwiftUI
import MetalKit
import Metal
struct LidarCamera: View {
    @StateObject private var manager = CameraManager()
    
    @State private var maxDepth = Float(5.0)
    @State private var minDepth = Float(0.0)
    @State private var scaleMovement = Float(1.0)
    
    let maxRangeDepth = Float(15)
    let minRangeDepth = Float(0)
    @State var isRecording = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Depth Filtering")
                Toggle("Depth Filtering", isOn: $manager.isFilteringDepth).labelsHidden()
                Spacer()
            }
            Text(manager.recordedTime.positionalTime)
            ZStack{
                if manager.dataAvailable {  MetalTextureColorZapView(
                    rotationAngle: CGFloat(-Double.pi / 2),
                    maxDepth: $maxDepth,
                    minDepth: $minDepth,
                    capturedData: manager.capturedData
                ).aspectRatio(9/16, contentMode:.fit)
                }
            }
            RecordButton(isRecording: $isRecording) {
                manager.startRecording()
            } stopAction: {
                manager.outputVideoRecording()
            }.frame(width: 70, height: 70)
        }
    }
    
}
