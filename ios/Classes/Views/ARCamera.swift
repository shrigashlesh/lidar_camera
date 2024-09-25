import SwiftUI
import ARKit
import ARVideoKit
import SwiftUI
import Photos
import RealityKit

struct ARRecordingView: View {
    @StateObject var arViewModel = ARViewModel()
    
    var body: some View {
        ZStack {
            ARViewContainer(arViewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                RecordButton(isRecording: $arViewModel.isRecording, startAction: {
                    arViewModel.startRecording()
                }, stopAction:{
                    arViewModel.stopRecording()
                    
                })    .frame(width: 70, height: 70)
            }
            .padding()
        }
    }
}


struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arViewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        
        let configuration = ARWorldTrackingConfiguration()
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            configuration.sceneReconstruction = .meshWithClassification
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        // Initialize ARVideoKit recorder
        guard let recorder = RecordAR(ARSceneKit: arView) else {
            return arView
        }
        recorder.delegate = arViewModel
        recorder.onlyRenderWhileRecording = true
        recorder.contentMode = .aspectFill
        recorder.enableAdjustEnvironmentLighting = true
        recorder.inputViewOrientations = [.landscapeLeft, .landscapeRight, .portrait]
        recorder.deleteCacheWhenExported = true
        recorder.fps = .fps30
        recorder.enableAudio = true
        recorder.requestMicPermission = .auto
        recorder.prepare(configuration)
        arViewModel.recorder = recorder
        
        arView.session.delegate = arViewModel
        arView.session.run(configuration)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Optional: You can handle view updates here
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        
        
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        
    }
}
class ARViewModel: NSObject, ARSessionDelegate, ObservableObject, RecordARDelegate {
    
    var recorder: RecordAR?
    let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    let frameBufferingQueue = DispatchQueue(label: "frameBufferingQueue", qos: .background)

    var lastTimeStamp: TimeInterval = 0.0
    var bufferedFrames = [ARDepthConversionData]()
    
    @Published var isRecording : Bool = false
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if(recorder?.status == .recording){
            frameBufferingQueue.sync {
                let transform = frame.camera.transform
                let intrinic = frame.camera.intrinsics
                guard let depthData = frame.sceneDepth?.asBytes() else {
                    return
                }
//                bufferedFrames.append(ARDepthConversionData(depth: depthData, cameraIntrinsic: intrinic, viewTransform: transform, timeStamp: lastTimeStamp))
            }
        }
    }
    
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError {
            print(bufferedFrames.count)
            print(path)
        }
    }
    
    func recorder(didUpdateRecording duration: TimeInterval) {
        print("DURATION:", duration)
    }
    
    func recorder(didFailRecording error: (any Error)?, and status: String) {
        
    }
    
    func recorder(willEnterBackground status: ARVideoKit.RecordARStatus) {
        if status == .recording {
            recorder?.stopAndExport()
        }
    }
    
    func startRecording() {
        if recorder?.status == .readyToRecord {
            recordingQueue.async {
                self.recorder?.record(forDuration: 4) { path in
                    self.recorder?.export(video: path) { saved, status in
                        DispatchQueue.main.async {
                            self.exportMessage(success: saved, status: status)
                        }
                    }
                }
            }
        }
    }
    
    func stopRecording() {
        if recorder?.status == .recording {
            recordingQueue.async {
                self.recorder?.stop( {path in
                    self.recorder?.export(video: path) { saved, status in
                        DispatchQueue.main.async {
                            self.exportMessage(success: saved, status: status)
                        }
                    }
                })
            }
        }
    }
    
    private func exportMessage(success: Bool, status: PHAuthorizationStatus) {
        if success {
            print("Media exported to camera roll successfully!")
        } else if status == .denied || status == .restricted || status == .notDetermined {
            print("Please allow access to the photo library in order to save this media file.")
        } else {
            print("There was an error while exporting your media file.")
        }
    }
}



