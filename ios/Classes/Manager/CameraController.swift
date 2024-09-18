import UIKit
import AVFoundation
import CoreImage
import Photos

// Protocol to notify when new camera data is captured.
protocol CaptureDataReceiver: AnyObject {
    func onNewData(capturedData: CameraCapturedData)
}

// Protocol to notify when the updated timestamp.
protocol CaptureTimeReceiver: AnyObject {
    func onRecordingTimeUpdate(recordedTime: CMTime)
}

class CameraController: NSObject, ObservableObject, AVPlayerItemMetadataOutputPushDelegate {
    
    // Custom error types for configuration failures.
    enum ConfigurationError: Error {
        case lidarDeviceUnavailable
        case requiredFormatUnavailable
        case micUnavailable
    }
    
    // Desired video resolution for capture.
    private let preferredWidthResolution = 1080
    private let preferredHeightResolution = 1920
    
    // Queue to handle video processing with high priority.
    private let videoQueue = DispatchQueue(label: "lidar_camera_videoQueue", qos: .userInteractive)
    
    // Capture session object to manage input/output.
    private(set) var captureSession: AVCaptureSession!
    
    // Outputs for depth data and video data.
    private var depthDataOutput: AVCaptureDepthDataOutput!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    
    // Synchronizer to align depth and video outputs.
    private var outputVideoSync: AVCaptureDataOutputSynchronizer!
    
    // Metal texture cache for managing video frames.
    private var textureCache: CVMetalTextureCache!
    
    // AVAssetWriter components for video recording.
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    private var bufferedDepthConversionData: DepthConversionDataContainer?
    
    // Timestamp to manage frame timing during video recording.
    private var lastTimestamp: CMTime = .zero
    
    // Delegate to notify when new captured data is available.
    weak var captureDelegate: CaptureDataReceiver?
    weak var timeReceiverDelegate: CaptureTimeReceiver?
    
    // Property to enable or disable depth filtering.
    var isFilteringEnabled = false {
        didSet {
            depthDataOutput?.isFilteringEnabled = isFilteringEnabled
        }
    }
    
    // Property to control video recording state.
    var isRecording = false {
        didSet {
            if isRecording {
                startRecording()
            } else {
                finishRecording()
            }
        }
    }
    
    var fileName: String?
    override init() {
        super.init()
        
        // Create a Metal texture cache for video processing.
        CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                  nil,
                                  MetalEnvironment.shared.metalDevice,
                                  nil,
                                  &textureCache)
        
        checkAuthorization()
    }
    
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status {
                    self.setupSession()
                }
            }
            break
        case .denied:
            break
        default:
            break
        }
    }
    
    // Set up the capture session with camera inputs and outputs.
    private func setupSession() {
        do {
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = .hd1920x1080
            
            // Begin configuration before adding inputs/outputs.
            captureSession.beginConfiguration()
            
            try setupCaptureInput()  // Configure the camera input.
            setupCaptureOutputs()    // Configure video and depth outputs.
            
            // Finalize and commit the session configuration.
            captureSession.commitConfiguration()
        } catch {
            fatalError("Unable to configure the capture session.")
        }
    }
    
    // Set up the camera input (LiDAR) for depth data and video.
    private func setupCaptureInput() throws {
        // Ensure the LiDAR camera is available.
        guard let lidarDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else {
            throw ConfigurationError.lidarDeviceUnavailable
        }
        
        // Find a suitable format for video that meets the required resolution.
        guard let format = (lidarDevice.formats.last { format in
            format.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange &&
            !format.isVideoBinned &&
            !format.supportedDepthDataFormats.isEmpty
        }) else {
            throw ConfigurationError.requiredFormatUnavailable
        }
        
        // Find a suitable depth data format.
        guard let depthFormat = (format.supportedDepthDataFormats.last { depthFormat in
            depthFormat.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_DepthFloat32
        }) else {
            throw ConfigurationError.requiredFormatUnavailable
        }
        
        // Lock the device for configuration and set the formats.
        try lidarDevice.lockForConfiguration()
        lidarDevice.activeFormat = format
        lidarDevice.activeDepthDataFormat = depthFormat
        lidarDevice.unlockForConfiguration()
        
        // Add the camera input to the capture session.
        let lidarCameraInput = try AVCaptureDeviceInput(device: lidarDevice)
        captureSession.addInput(lidarCameraInput)
    }
    
    // Set up the outputs for video and depth data.
    private func setupCaptureOutputs() {
        // Configure the video data output for the session.
        videoDataOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(videoDataOutput)
        
        // Configure the depth data output for the session.
        depthDataOutput = AVCaptureDepthDataOutput()
        depthDataOutput.isFilteringEnabled = isFilteringEnabled
        captureSession.addOutput(depthDataOutput)
        
        guard let depthConnection = depthDataOutput.connection(with: .depthData) else { return }
        depthConnection.videoOrientation = .portrait
        
        // Synchronize depth and video outputs.
        outputVideoSync = AVCaptureDataOutputSynchronizer(dataOutputs: [depthDataOutput, videoDataOutput])
        outputVideoSync.setDelegate(self, queue: videoQueue)
        
        // Enable the camera's intrinsic matrix delivery for advanced processing.
        guard let outputConnection = videoDataOutput.connection(with: .video) else { return }
        outputConnection.videoOrientation = .portrait
        if outputConnection.isCameraIntrinsicMatrixDeliverySupported {
            outputConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
        }
    }
    
    // Start the camera stream.
    func startStream() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    // Stop the camera stream.
    func stopStream() {
        captureSession.stopRunning()
    }
    
    // Start recording video, setting up the asset writer.
    private func startRecording() {
        fileName = UUID().uuidString
        guard let fileName = fileName else { return }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).mov")
        do {
            // Set up the asset writer for video recording.
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            lastTimestamp = .zero
            
            // Configure video settings.
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: preferredWidthResolution,
                AVVideoHeightKey: preferredHeightResolution
            ]
            
            // Add inputs for video frames and metadata.
            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            assetWriterInput?.expectsMediaDataInRealTime = true
            
            assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: assetWriterInput!,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                ]
            )
            
            
            // Start writing session for video and metadata.
            if let assetWriter = assetWriter,
               let assetWriterInput = assetWriterInput
            {
                bufferedDepthConversionData = DepthConversionDataContainer()
                assetWriter.add(assetWriterInput)
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: .zero)
            }
        } catch {
            print("Error starting video recording: \(error)")
        }
    }
    
    // Append video frames and depth data during recording.
    private func appendPixelBufferAndDepth(pixelBuffer: CVPixelBuffer, depthData: AVDepthData, timestamp: CMTime) {
        guard let assetWriterPixelBufferInput = assetWriterPixelBufferInput else { return }
        
        // Set frame duration for 30fps video.
        let frameDuration = CMTime(seconds: 1.0 / 30.0, preferredTimescale: 600)
        lastTimestamp = CMTimeAdd(lastTimestamp, frameDuration)
        // Append pixel buffer if the writer is ready.
        if assetWriterPixelBufferInput.assetWriterInput.isReadyForMoreMediaData {
            assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: lastTimestamp)
        }
        // Add depth and camera data to buffer for saving later
        bufferDepthAndCameraData(depthData: depthData)
    }
    
    private func bufferDepthAndCameraData(depthData: AVDepthData) {
        // Flatten the depth array
        let depthValues = depthData.extractDepthMap2D()
        
        // Extract camera intrinsic matrix and view transform
        guard let cameraCalibrationData = depthData.cameraCalibrationData else {
            print("No camera calibration data available")
            return
        }
        
        let cameraIntrinsicMatrix = serializeMatrix3x3(cameraCalibrationData.intrinsicMatrix)
        let viewTransformMatrix = serializeMatrix(cameraCalibrationData.extrinsicMatrix)
        
        
        // Create an instance of DepthConversionData
        let depthConversionData = DepthConversionData(
            depth: depthValues,
            cameraIntrinsic: cameraIntrinsicMatrix,
            viewTransform: viewTransformMatrix
        )
        
        // Convert the CMTime to a readable format, such as seconds
        let timestampKey = String(CMTimeGetSeconds(lastTimestamp))
        bufferedDepthConversionData?.timestampedData[timestampKey] = depthConversionData
    }
    
    
    // Reset recording state and inputs after a session.
    private func resetRecordingState() {
        assetWriter = nil
        assetWriterInput = nil
        assetWriterPixelBufferInput = nil
        bufferedDepthConversionData = DepthConversionDataContainer()
    }
    
    // Finalize and complete the video recording.
    private func finishRecording() {
        DispatchQueue.global(qos: .utility).async{
            self.saveBufferedDataToFile()
        }
        // Write the buffered metadata after video is saved
        if assetWriter?.status == .writing {
            assetWriter?.finishWriting { [weak self] in
                guard let self = self else { return }
                
                if let videoURL = self.assetWriter?.outputURL {
                    
                    DispatchQueue.main.async { [self] in
                        print("Saving video to gallery at path: \(videoURL.path)")
                        self.saveVideoWithMetadata(videoURL: videoURL)
                    }
                    self.resetRecordingState()
                }
            }
        } else {
            print("Asset Writer not in a writable state: \(String(describing: assetWriter?.status))")
        }
    }
    
    private func saveBufferedDataToFile() {
        guard let fileName = fileName else {return}
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            try JSONFileIO().write(bufferedDepthConversionData, toDocumentNamed: fileName, encodedUsing: encoder)
            print("Successfully saved depth conversion data to \(fileName)")
        } catch {
            print("Failed to save metadata to JSON file: \(error)")
        }
    }
    
    func saveVideoWithMetadata(videoURL: URL) {
        // Request authorization if not already done
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Permission not granted to access photo library")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                // Create a new asset creation request
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL: videoURL, options: nil)
                creationRequest.creationDate = Date()
                
            }) { success, error in
                if success {
                    print("Video saved successfully to user photo library.")
                } else if let error = error {
                    print("Error saving video: \(error.localizedDescription)")
                }
            }
        }
        
    }
}

// AVCaptureDataOutputSynchronizerDelegate method to handle synchronized video and depth data.
extension CameraController: AVCaptureDataOutputSynchronizerDelegate {
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer,
                                didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        
        // Retrieve the synchronized depth and sample buffer container objects.
        guard let syncedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData,
              let syncedVideoData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData else { return }
        
        if syncedDepthData.depthDataWasDropped || syncedVideoData.sampleBufferWasDropped {
            return
        }
        
        let depthData = syncedDepthData.depthData
        let sampleBuffer = syncedVideoData.sampleBuffer
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let cameraCalibrationData = depthData.cameraCalibrationData else {
            return
        }
        
        // Package the captured data.
        let data = CameraCapturedData(
            depth: syncedDepthData.depthData.depthDataMap.texture(withFormat: .r16Float, planeIndex: 0, addToCache: textureCache),
            colorY: videoPixelBuffer.texture(withFormat: .r8Unorm, planeIndex: 0, addToCache: textureCache),
            colorCbCr: videoPixelBuffer.texture(withFormat: .rg8Unorm, planeIndex: 1, addToCache: textureCache),
            cameraIntrinsics: cameraCalibrationData.intrinsicMatrix,
            cameraReferenceDimensions: cameraCalibrationData.intrinsicMatrixReferenceDimensions)
        
        captureDelegate?.onNewData(capturedData: data)
        
        guard isRecording else { return }
        DispatchQueue.main.async {
            self.timeReceiverDelegate?.onRecordingTimeUpdate(recordedTime: self.lastTimestamp)
        }
        appendPixelBufferAndDepth(pixelBuffer: videoPixelBuffer, depthData: depthData, timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
    }
}
