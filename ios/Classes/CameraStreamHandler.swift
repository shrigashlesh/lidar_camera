//
//  CameraStreamHandler.swift
//  Pods
//
//  Created by Shrig0001 on 23/05/2025.
//

import Foundation
import ARKit
import Flutter
import UIKit
import Metal
import CoreImage
import RealityKit

final class CameraStreamHandler: NSObject, FlutterStreamHandler {
    
    // MARK: - Singleton
    static let shared = CameraStreamHandler()
    
    // MARK: - Properties
    private var eventSink: FlutterEventSink?
    private var displayLink: CADisplayLink?
    private var activeSceneView: ARView?

    // Frame throttling
    private var lastFrameTime = CACurrentMediaTime()
    private let targetFPS: Double = 10.0
    private var frameInterval: CFTimeInterval { 1.0 / targetFPS }

    // Background processing
    private let processingQueue = DispatchQueue(label: "camera frame stream processing queue")

    // CIContext with Metal acceleration
    private lazy var ciContext: CIContext = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal device not available")
        }
        return CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .cacheIntermediates: false
        ])
    }()

    // Image processing constants
    private struct Settings {
        static let scale: CGFloat = 0.3
        static let jpegQuality: CGFloat = 0.35
        static let depthStride = 4
        static let rotation: CGFloat = -.pi / 2
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        print("CameraStreamHandler: Initialized")
    }

    deinit {
        cleanup()
    }

    // MARK: - Public Methods
    
    func setActiveARView(_ sceneView: ARView) {
        print("CameraStreamHandler: Setting active scene view")
        stopCameraStreaming()
        activeSceneView = sceneView
        if eventSink != nil { startCameraStreaming() }
    }
    
    func clearActiveSceneView() {
        print("CameraStreamHandler: Clearing active scene view")
        cleanup()
    }

    // MARK: - Private Methods

   private func startCameraStreaming() {
        guard displayLink == nil, activeSceneView != nil else {
            print("CameraStreamHandler: Cannot start streaming - missing requirements")
            return
        }

        print("CameraStreamHandler: Starting camera streaming at \(targetFPS) FPS")
        displayLink = CADisplayLink(target: self, selector: #selector(streamCameraFrame))
        displayLink?.preferredFramesPerSecond = Int(targetFPS * 2)
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopCameraStreaming() {
        print("CameraStreamHandler: Stopping camera streaming")
        displayLink?.invalidate()
        displayLink = nil
    }

    private func cleanup() {
        stopCameraStreaming()
        activeSceneView = nil
        eventSink = nil
    }

    @objc private func streamCameraFrame() {
        let now = CACurrentMediaTime()
        guard now - lastFrameTime >= frameInterval else { return }
        lastFrameTime = now

        guard let sceneView = activeSceneView,
              let frame = sceneView.session.currentFrame,
              let eventSink = eventSink else { return }

        processingQueue.async { [weak self] in
            self?.processFrame(frame, eventSink: eventSink)
        }
    }

    private func processFrame(_ frame: ARFrame, eventSink: @escaping FlutterEventSink) {
        autoreleasepool {
            var result: [String: Any] = [:]

            if let rgbFrameData = processCameraImage(frame.capturedImage) {
                result.merge(rgbFrameData) { _, new in new }
            }

            DispatchQueue.main.async {
                eventSink(result)
            }
        }
    }

    private func processCameraImage(_ pixelBuffer: CVPixelBuffer) -> [String: Any]? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            .transformed(by: CGAffineTransform(scaleX: Settings.scale, y: Settings.scale)
            .rotated(by: Settings.rotation))

        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }

        guard let jpegData = UIImage(cgImage: cgImage).jpegData(compressionQuality: Settings.jpegQuality) else {
            print("Failed to encode JPEG")
            return nil
        }

        return [
            "frameBytes": FlutterStandardTypedData(bytes: jpegData),
            "width": cgImage.width,
            "height": cgImage.height
        ]
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("CameraStreamHandler: onListen")
        eventSink = events
        if activeSceneView != nil {
            startCameraStreaming()
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("CameraStreamHandler: onCancel")
        cleanup()
        return nil
    }
}
