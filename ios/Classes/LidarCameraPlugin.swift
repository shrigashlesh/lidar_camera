import Flutter
import UIKit

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
