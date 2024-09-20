//
//  LidarCamera.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 16/09/2024.
//
import SwiftUI
import MetalKit
import Metal
import SwiftUI
import MetalKit
import Metal

struct LidarCamera: View {
    @StateObject private var manager = CameraManager()
    let previewCornerRadius: CGFloat = 15.0
    @State private var maxDepth = Float(5.0)
    @State private var minDepth = Float(0.0)
    @State private var scaleMovement = Float(1.0)
    
    let maxRangeDepth = Float(15)
    let minRangeDepth = Float(0)
    @State var isRecording = false
    
    var body: some View {
        GeometryReader{geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if manager.dataAvailable {     VStack {
                    let width = geometry.size.width
                    let height = width * 16 / 9 // 4:3 aspect ratio
                    // Metal view that displays the depth data
                    RecordedTimeView(
                        positionalTime: manager.recordedTime.positionalTime,
                        isRecording: isRecording
                    )
                    Spacer()

                    MetalTextureDepthView(
                        rotationAngle: CGFloat(-Double.pi/2),
                        maxDepth: $maxDepth,
                        minDepth: $minDepth,
                        capturedData: manager.capturedData
                    ).clipShape(RoundedRectangle(cornerRadius: previewCornerRadius))
                        .frame(width: width, height: height)
                    
                    
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
    }
}
