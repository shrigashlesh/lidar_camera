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

class CameraController: NSObject, ObservableObject {
    
    // Desired video resolution for capture.
    private let preferredWidthResolution = 1920
    private let preferredHeightResolution = 1080
    
    // Queue to handle video processing with high priority.
    private let videoQueue = DispatchQueue(label: "lidar_camera_videoQueue", qos: .userInteractive)
    private let audioQueue = DispatchQueue(label: "lidar_camera_audioQueue", qos: .userInteractive)
    
    // Capture session object to manage input/output.
    private(set) var captureSession: AVCaptureSession?
    private(set) var audioCaptureSession: AVCaptureSession?
    
    // Outputs for depth data and video data.
    private var depthDataOutput: AVCaptureDepthDataOutput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var audioDataOutput: AVCaptureAudioDataOutput?
    
    // Synchronizer to align depth and video outputs.
    private var outputVideoSync: AVCaptureDataOutputSynchronizer!
    
    // Metal texture cache for managing video frames.
    private var textureCache: CVMetalTextureCache!
    
    // AVAssetWriter components for video recording.
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var bufferedDepthConversionData: [DepthConversionData] = []
    
    // Timestamp to manage frame timing during video recording.
    private var lastTimestamp: CMTime = .zero
    
    // Delegate to notify when new captured data is available.
    weak var captureDelegate: CaptureDataReceiver?
    weak var timeReceiverDelegate: CaptureTimeReceiver?
    
    private var videoPermissionGranted = false
    private var microphonePermissionGranted = false
    
    // Property to enable or disable depth filtering.
    var isFilteringEnabled = true {
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
    
    var videoFileName: String?
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
    
    private func cleanup() {
        print("CAMERA CONTROLLER CLEANUP")
        
        // Stop capture sessions
        captureSession?.stopRunning()
        audioCaptureSession?.stopRunning()
        
        // Release capture session objects
        captureSession = nil
        audioCaptureSession = nil
        
        // Release outputs
        depthDataOutput = nil
        videoDataOutput = nil
        audioDataOutput = nil
        
        // Release synchronizer
        outputVideoSync = nil
        
        // Release Metal texture cache
        if let textureCache = textureCache {
            CVMetalTextureCacheFlush(textureCache, 0)
            self.textureCache = nil
        }
        
        // Release AVAssetWriter components
        assetWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
        assetWriter?.finishWriting {
            
        }
        resetRecordingState()
        
        // Release delegates
        captureDelegate = nil
        timeReceiverDelegate = nil
    }
    
    deinit {
        cleanup()
    }
    
    func checkAuthorization() {
        let dispatchGroup = DispatchGroup()
        
        // Check video authorization status
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            videoPermissionGranted = true
        case .notDetermined:
            dispatchGroup.enter()  // Enter the dispatch group
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
                self?.videoPermissionGranted = granted
                dispatchGroup.leave()  // Leave the dispatch group when done
            }
        case .denied, .restricted:
            videoPermissionGranted = false
        @unknown default:
            break
        }
        
        // Check microphone authorization status
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphonePermissionGranted = true
        case .undetermined:
            dispatchGroup.enter()  // Enter the dispatch group
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] (granted) in
                self?.microphonePermissionGranted = granted
                dispatchGroup.leave()  // Leave the dispatch group when done
            }
        case .denied:
            microphonePermissionGranted = false
        @unknown default:
            break
        }
        
        // Wait for both permissions to be processed
        dispatchGroup.notify(queue: .main) { [weak self] in
            if self?.videoPermissionGranted == true && self?.microphonePermissionGranted == true {
                self?.setupSession()  // Only setup the session if both permissions are granted
            }
        }
    }
    
    
    // Set up the capture session with camera inputs and outputs.
    private func setupSession() {
        do {
            captureSession = AVCaptureSession()
            audioCaptureSession = AVCaptureSession()
            guard let captureSession = captureSession,let audioCaptureSession = audioCaptureSession else {
                throw ConfigurationError.sessionUnavailable
            }
            captureSession.sessionPreset = .hd1920x1080
            audioCaptureSession.automaticallyConfiguresApplicationAudioSession = false
            // Begin configuration before adding inputs/outputs.
            captureSession.beginConfiguration()
            audioCaptureSession.beginConfiguration()
            
            try setupCaptureInput()  // Configure the camera input.
            try setupCaptureOutputs()    // Configure video and depth outputs.
            
            // Finalize and commit the session configuration.
            captureSession.commitConfiguration()
            audioCaptureSession.commitConfiguration()
            startStream()
        } catch {
            
            print("Unable to configure the capture session.")
        }
    }
    
    // Set up the camera input (LiDAR) for depth data, video, and audio.
    private func setupCaptureInput() throws {
        guard let captureSession = captureSession,let audioCaptureSession = audioCaptureSession else {
            throw ConfigurationError.sessionUnavailable
        }
        // Ensure the LiDAR camera is available.
        guard let lidarDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) else {
            throw ConfigurationError.lidarDeviceUnavailable
        }
        
        // Filter formats that match the required resolution and other conditions.
        let matchingFormats = lidarDevice.formats.filter {format in
            format.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange &&
            format.formatDescription.dimensions.width == preferredWidthResolution &&
            !format.isVideoBinned &&
            !format.supportedDepthDataFormats.isEmpty
        }
        // Find the first suitable format.
        guard let format = matchingFormats.first else {
            throw ConfigurationError.requiredFormatUnavailable
        }
        
        // Find a suitable depth data format.
        let depthFormats = format.supportedDepthDataFormats
        let depth16formats = depthFormats.filter({
            CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat16
        })
        
        if depth16formats.isEmpty {
            print("Device does not support Float16 depth format")
            throw ConfigurationError.requiredFormatUnavailable
        }
        let selectedDepthFormat = depth16formats.max(by: { first, second in
            CMVideoFormatDescriptionGetDimensions(first.formatDescription).width <
                CMVideoFormatDescriptionGetDimensions(second.formatDescription).width })
        
        // Lock the device for configuration and set the formats.
        try lidarDevice.lockForConfiguration()
        lidarDevice.activeFormat = format
        lidarDevice.activeDepthDataFormat = selectedDepthFormat
        lidarDevice.unlockForConfiguration()
        
        // Add the camera input to the capture session.
        let lidarCameraInput = try AVCaptureDeviceInput(device: lidarDevice)
        captureSession.addInput(lidarCameraInput)
        
        // Set up audio input (microphone)
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw ConfigurationError.micUnavailable
        }
        
        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
        audioCaptureSession.addInput(audioInput)  // Add the audio input to the capture session.
    }
    
    // Set up the outputs for video, depth data, and audio.
    private func setupCaptureOutputs() throws{
        guard let captureSession = captureSession,let audioCaptureSession = audioCaptureSession else {
            throw ConfigurationError.sessionUnavailable
        }
        // Configure the video data output for the session.
        videoDataOutput = AVCaptureVideoDataOutput()
        guard let videoDataOutput = videoDataOutput else {return}
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoDataOutput)
        
        // Configure the audio data output.
        audioDataOutput = AVCaptureAudioDataOutput()
        guard let audioDataOutput = audioDataOutput else {return}
        audioDataOutput.setSampleBufferDelegate(self, queue: audioQueue)
        audioCaptureSession.addOutput(audioDataOutput)
        
        // Configure the depth data output for the session.
        depthDataOutput = AVCaptureDepthDataOutput()
        guard let depthDataOutput = depthDataOutput else {return}
        depthDataOutput.isFilteringEnabled = isFilteringEnabled
        captureSession.addOutput(depthDataOutput)
        
        // Synchronize depth, video, and audio outputs.
        outputVideoSync = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
        outputVideoSync.setDelegate(self, queue: videoQueue)
        
        // Enable the camera's intrinsic matrix delivery for advanced processing.
        guard let depthConnection = depthDataOutput.connection(with: .depthData) else { return }
        depthConnection.videoOrientation = .portrait
        guard let outputConnection = videoDataOutput.connection(with: .video) else { return }
        outputConnection.videoOrientation = .portrait
        if outputConnection.isCameraIntrinsicMatrixDeliverySupported {
            outputConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
        }
    }
    
    // Start the camera stream.
    func startStream() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
    }
    
    // Start recording video, setting up the asset writer.
    private func startRecording() {
        videoFileName = UUID().uuidString
        guard let videoFileName = videoFileName else { return }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(videoFileName).mov")
        do {
            try self.activateAudioSession()
            // Set up the asset writer for video recording.
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            // Configure video settings.
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: preferredHeightResolution,
                AVVideoHeightKey: preferredWidthResolution
            ]
            
            // Audio settings.
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000
            ]
            
            
            // Add inputs for video frames and metadata.
            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            assetWriterInput?.expectsMediaDataInRealTime = true
            
            audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioWriterInput?.expectsMediaDataInRealTime = true
            
            // Start writing session for video and metadata.
            if let assetWriter = assetWriter,
               let assetWriterInput = assetWriterInput ,
               let audioWriterInput = audioWriterInput, let captureSession = captureSession
                
            {
                bufferedDepthConversionData = []
                lastTimestamp = .zero
                assetWriter.add(assetWriterInput)
                assetWriter.add(audioWriterInput)
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: CMClockGetTime(captureSession.clock))
            }
        } catch {
            print("Error starting video recording: \(error)")
        }
    }
    
    // Append video frames, audio and depth data during recording.
    private func appendVideoBufferAndDepth(buffer: CMSampleBuffer, depthData: AVDepthData) {
        guard let assetWriter = assetWriterInput else { return }
        
        // Set frame duration for 30fps video.
        let frameDuration = CMTime(seconds: 1.0 / 30.0, preferredTimescale: 600)
        lastTimestamp = CMTimeAdd(lastTimestamp, frameDuration)
        
        // Append pixel buffer if the writer is ready.
        if assetWriter.isReadyForMoreMediaData {
            assetWriter.append(buffer)
        }
        
        // Add depth and camera data to buffer for saving later
        bufferDepthAndCameraData(depthData: depthData)
    }
    
    
    private func bufferDepthAndCameraData(depthData: AVDepthData) {
        // Extract camera intrinsic matrix and view transform
        guard let cameraCalibrationData = depthData.cameraCalibrationData else {
            print("No camera calibration data available")
            return
        }
        
        let cameraIntrinsicMatrix = serializeMatrixToData(cameraCalibrationData.intrinsicMatrix)
        let viewTransformMatrix = serializeMatrixToData(cameraCalibrationData.extrinsicMatrix)
        guard let depthBytes = depthData.asBytes() else {
            return
        }
        // Create an instance of DepthConversionData
        let depthConversionData = DepthConversionData(
            depth: depthBytes,
            cameraIntrinsic: cameraIntrinsicMatrix,
            viewTransform: viewTransformMatrix,
            timeStamp: CMTimeGetSeconds(lastTimestamp)
        )
        
        bufferedDepthConversionData.append(depthConversionData)
    }
    
    
    // Reset recording state and inputs after a session.
    private func resetRecordingState() {
        assetWriter = nil
        assetWriterInput = nil
        audioWriterInput = nil
        bufferedDepthConversionData = []
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
                        self.saveVideoToGallery(videoURL: videoURL)
                    }
                    self.resetRecordingState()
                }
            }
        } else {
            print("Asset Writer not in a writable state: \(String(describing: assetWriter?.status))")
        }
    }
    
    private func saveBufferedDataToFile() {
        guard let videoFileName = videoFileName else { return }
        let fileIo = BinaryFileIO()
        for depthConversionData in bufferedDepthConversionData {
            // Calculate frame number from timestamp
            let frameNumber = frameNumber(from: depthConversionData.timeStamp)
            
            // Define file names based on frame number
            let depthFileName = "depth_\(frameNumber)"
            let cameraIntrinsicFileName = "cameraIntrinsic_\(frameNumber)"
            let viewTransformFileName = "viewTransform_\(frameNumber)"
            
            do {
                // Save depth data
                try fileIo.write(depthConversionData.depth, folder: videoFileName, toDocumentNamed: depthFileName)
                
                // Save camera intrinsic matrix
                try fileIo.write(depthConversionData.cameraIntrinsic, folder: videoFileName, toDocumentNamed: cameraIntrinsicFileName)
                
                // Save view transform matrix
                try fileIo.write(depthConversionData.viewTransform, folder: videoFileName, toDocumentNamed: viewTransformFileName)
            } catch {
                print("Failed to save data: \(error)")
            }
        }
    }
    
    func frameNumber(from timestamp: Float64) -> String {
        // Calculate frame number
        let frameNumber = Int64(round(timestamp * 30))
        
        return String(format: "%04d", frameNumber)
    }
    
    func saveVideoToGallery(videoURL: URL) {
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
extension CameraController: AVCaptureDataOutputSynchronizerDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer,
                                didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        
        guard let videoDataOutput = videoDataOutput,
              let depthDataOutput = depthDataOutput else { return }
        
        
        // Retrieve the synchronized depth, and video data
        guard let syncedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData,
              let syncedVideoData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData else { return }
        
        // Check if any data was dropped
        if syncedDepthData.depthDataWasDropped || syncedVideoData.sampleBufferWasDropped  {
            return
        }
        
        let depthData = syncedDepthData.depthData
        let videoSampleBuffer = syncedVideoData.sampleBuffer
        
        // Process video data
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(videoSampleBuffer),
              let cameraCalibrationData = depthData.cameraCalibrationData else {
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
        
        // Append video and depth data to recording
        guard isRecording else { return }
        DispatchQueue.main.async {
            self.timeReceiverDelegate?.onRecordingTimeUpdate(recordedTime: self.lastTimestamp)
        }
        appendVideoBufferAndDepth(buffer: videoSampleBuffer, depthData: depthData)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == audioDataOutput {
            guard let audioWriterInput = audioWriterInput, let captureSession = captureSession, let audioCaptureSession = audioCaptureSession else { return }
            
            // Ensure the audio writer input is ready for more data
            if audioWriterInput.isReadyForMoreMediaData {
                audioCaptureSession.synchronizeBuffer(sampleBuffer, toSession: captureSession)
                audioWriterInput.append(sampleBuffer)
            }
        }
    }
}


extension AVCaptureSession {
    /**
     Returns the clock that is used by this AVCaptureSession.
     */
    var clock: CMClock {
        if #available(iOS 15.4, *), let synchronizationClock {
            return synchronizationClock
        }
        
        return CMClockGetHostTimeClock()
    }
    
    /**
     Synchronizes a Buffer received from this [AVCaptureSession] to the timebase of the other given [AVCaptureSession].
     */
    func synchronizeBuffer(_ buffer: CMSampleBuffer, toSession to: AVCaptureSession) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(buffer)
        let synchronizedTimestamp = CMSyncConvertTime(timestamp, from: clock, to: to.clock)
        CMSampleBufferSetOutputPresentationTimeStamp(buffer, newValue: synchronizedTimestamp)
    }
}
