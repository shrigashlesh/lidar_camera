import Flutter
import UIKit
import Foundation

public class LidarCameraPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let lidarFactory = FlutterLidarCameraFactory(messenger: registrar.messenger())
        registrar.register(lidarFactory, withId: "lidar_cam_view")
        
        let channel = FlutterMethodChannel(name: "lidar_camera", binaryMessenger: registrar.messenger())
        let instance = LidarCameraPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkLidarAvailability":
            result(true)
        case "readDepthConversionData":
            guard let arguments = call.arguments as? [String: Any],
                  let videoFileName = arguments["recordingUUID"] as? String,
                  let frameNumber = arguments["frameNumber"] as? Int else{
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument in readDepthConversionData call", details: nil))
                return
            }
            do {
                let depthFileName = Helper.getDepthFileName(frameNumber: frameNumber)
                let intrinsicFileName = Helper.getIntrinsicFileName(frameNumber: frameNumber)
                let transformFileName = Helper.getTransformFileName(frameNumber: frameNumber)
                let fileIo = BinaryFileIO()
                // Read the three separate files
                let (depthData, depthDataFileUrl) = try fileIo.read(folder: videoFileName, fromDocumentNamed: depthFileName)
                let (cameraIntrinsicData, cameraIntrinsicFileUrl) = try fileIo.read(folder: videoFileName, fromDocumentNamed: intrinsicFileName)
                let (cameraTransformData, cameraTransfromFileUrl) = try fileIo.read(folder: videoFileName, fromDocumentNamed: transformFileName)
                
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
        default:
            result(FlutterMethodNotImplemented)
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
