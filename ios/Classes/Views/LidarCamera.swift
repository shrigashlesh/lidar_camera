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
        
        //            HStack {
        //                Text("Depth Filtering")
        //                Toggle("Depth Filtering", isOn: $manager.isFilteringDepth).labelsHidden()
        //            }
        ZStack {
            
            // Metal view that displays the depth data
            if manager.dataAvailable {
                MetalTextureColorZapView(
                    rotationAngle: CGFloat(-Double.pi / 2),
                    maxDepth: $maxDepth,
                    minDepth: $minDepth,
                    capturedData: manager.capturedData
                )
                .aspectRatio(9/16, contentMode: .fill)
                .clipped()
            }
            
            VStack {
                RecordedTimeView(
                    positionalTime: manager.recordedTime.positionalTime,
                    isRecording: isRecording
                )
                Spacer()
                RecordButton(isRecording: $isRecording) {
                    manager.startRecording()
                } stopAction: {
                    manager.outputVideoRecording()
                }
                .frame(width: 70, height: 70)
            }.padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
        }
    }
}
