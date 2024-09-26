import Flutter
import UIKit

class FlutterLidarCameraView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var viewController: UIViewController?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        createNativeView(view: _view)
    }
    
    func view() -> UIView {
        return _view
    }
    
    func createNativeView(view _view: UIView){
        let topController = UIApplication.shared.keyWindowPresentedController
        
        let vc = CameraViewController()
        viewController = vc // Store reference to view controller
        let uiKitView = vc.view!
        uiKitView.translatesAutoresizingMaskIntoConstraints = false
        
        topController?.addChild(vc)
        _view.addSubview(uiKitView)
        
        NSLayoutConstraint.activate(
            [
                uiKitView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                uiKitView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                uiKitView.topAnchor.constraint(equalTo: _view.topAnchor),
                uiKitView.bottomAnchor.constraint(equalTo:  _view.bottomAnchor)
            ])
        
        vc.didMove(toParent: topController)
    }

    func cleanup() {
        // Ensure viewController is removed and cleaned up
        viewController?.willMove(toParent: nil)
        viewController?.view.removeFromSuperview()
        viewController?.removeFromParent()
        viewController = nil
    }
    
    deinit {
        cleanup()
    }
}
