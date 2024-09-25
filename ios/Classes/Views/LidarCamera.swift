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
    @State private var maxDepth = Float(15.0)
    @State private var minDepth = Float(0.0)
    @State private var scaleMovement = Float(1.0)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if manager.dataAvailable {
                    VStack {
                        RecordedTimeView(
                            positionalTime: manager.recordedTime.positionalTime,
                            isRecording: manager.isRecording
                        )

                        ZStack {
                            let width = geometry.size.width
                            let height = geometry.size.height

                            MetalTextureColorZapView(
                                rotationAngle: CGFloat(-Double.pi/2),
                                maxDepth: $maxDepth,
                                minDepth: $minDepth,                                 capturedData: manager.capturedData
                            )
                            .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius))
                            .frame(width: width, height: height)

                            VStack {
                                Spacer()
                                
                                RecordButton(isRecording: $manager.isRecording) {
                                } stopAction: {
                                }
                                .frame(width: 70, height: 70)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 40, trailing: 0))
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
            }
        }
    }
}
