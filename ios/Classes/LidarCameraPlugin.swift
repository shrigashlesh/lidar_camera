import Flutter
import UIKit
import Foundation
import Photos

public class LidarCameraPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let lidarFactory = FlutterLidarCameraFactory(messenger: registrar.messenger())
        registrar.register(lidarFactory, withId: "lidar_cam_view")
        
        let channel = FlutterMethodChannel(name: "lidar_data_reader", binaryMessenger: registrar.messenger())
        let instance = LidarCameraPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkLidarAvailability":
            checkLidarAvailability(result: result)
        case "readDepthConversionData":
            guard let arguments = call.arguments as? [String: Any],
                  let videoFileName = arguments["recordingUUID"] as? String,
                  let frameNumber = arguments["frameNumber"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument in readDepthConversionData call", details: nil))
                return
            }
            readDepthData(videoFileName: videoFileName, frameNumber: frameNumber, result: result)
        case "deleteRecording":
            guard let arguments = call.arguments as? [String: Any],
                  let recordingUUID = arguments["recordingUUID"] as? String,
                  let assetIdentifier = arguments["assetIdentifier"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument in deleteRecording call", details: nil))
                return
            }
            deleteRecording(recordingUUID: recordingUUID, assetIdentifier: assetIdentifier, result: result)
        case "checkRecordingDataAvailability":
            guard let arguments = call.arguments as? [String: Any],
                  let recordingUUID = arguments["recordingUUID"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument in checkRecordingDataAvailability call", details: nil))
                return
            }
            checkRecordingDataAvailability(recordingUUID: recordingUUID, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func checkLidarAvailability(result: @escaping FlutterResult) {
        if let device = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) {
            result(device.isConnected)
        } else {
            result(false) 
        }
    }
    
    private func checkRecordingDataAvailability(recordingUUID: String, result: @escaping FlutterResult) {
        do {
            let fileIo = BinaryFileIO()
            // Check if the folder for the recording UUID exists
            let folderExists = try fileIo.folderExists(folder: recordingUUID)
            result(folderExists)
        } catch {
            result(FlutterError(code: "CHECK_ERROR", message: "Failed to check recording availability: \(error.localizedDescription)", details: nil))
        }
    }

    
    private func readDepthData(videoFileName: String, frameNumber: Int, result: @escaping FlutterResult) {
        do {
            let depthFileName = Helper.getDepthFileName(frameNumber: frameNumber)
            let intrinsicFileName = Helper.getIntrinsicFileName(frameNumber: frameNumber)
            let transformFileName = Helper.getTransformFileName(frameNumber: frameNumber)
            let fileIo = BinaryFileIO()
            // Read the three separate files
            let (depthData, depthDataFileUrl) = try fileIo.read(folder: videoFileName, fromDocumentNamed: depthFileName)
            let (cameraIntrinsicData, _) = try fileIo.read(folder: videoFileName, fromDocumentNamed: intrinsicFileName)
            let (cameraTransformData, _) = try fileIo.read(folder: videoFileName, fromDocumentNamed: transformFileName)
            
            guard let intrinsic = deserialize3x3Matrix(data: cameraIntrinsicData), let transform = deserialize4x4Matrix(data: cameraTransformData) else {
                result(FlutterError(code: "READ_ERROR", message: "Failed to read depth data", details: nil))
                return
            }
            // Convert the Data to base64 encoded strings
            let depthBase64 = depthData.base64EncodedString()
            let properties = [
                "depth": depthBase64,
                "intrinsic": serializeMatrix(intrinsic),
                "transform": serializeMatrix(transform),
                "depthFilePath": depthDataFileUrl.path
            ] as [String : Any]
            result(properties)
        } catch {
            result(FlutterError(code: "READ_ERROR", message: "Failed to read depth data", details: error.localizedDescription))
        }
    }
    
    func requestPhotosPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            completion(true)  // Already authorized
        case .limited:
            completion(true)  // Limited access granted
        case .denied, .restricted:
            completion(false) // Access denied
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func deleteRecording(recordingUUID: String,assetIdentifier: String, result: @escaping FlutterResult) {
        requestPhotosPermission { granted in
            if granted {
                // Proceed with deletion
                PHPhotoLibrary.shared().performChanges({
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", assetIdentifier)
                    let asset = PHAsset.fetchAssets(with: fetchOptions).firstObject
                    if let asset = asset {
                        PHAssetChangeRequest.deleteAssets([asset] as NSArray)
                    }
                }, completionHandler: { success, error in
                    if success {
                        // If video deleted from Photos, delete the folder
                        do {
                            let fileIo = BinaryFileIO()
                            try fileIo.deleteFolder(folder: recordingUUID)
                            result(true)
                        } catch {
                            result(FlutterError(code: "DELETE_ERROR", message: "Failed to delete folder: \(error.localizedDescription)", details: nil))
                        }
                    } else if let error = error {
                        result(FlutterError(code: "PHOTOS_DELETE_ERROR", message: "Failed to delete video from Photos: \(error.localizedDescription)", details: nil))
                    }
                })
            } else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Photos library access was denied.", details: nil))
            }
        }
    }
}

class FlutterLidarCameraFactory: NSObject, FlutterPlatformViewFactory {
    let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let view = FlutterLidarCameraView(frame: frame,
                                          viewIdentifier: viewId,
                                          arguments: args,
                                          binaryMessenger: messenger)
        return view
    }
}
