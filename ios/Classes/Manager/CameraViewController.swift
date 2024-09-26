//
//  CameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-11-20.
//  Copyright © 2020 jx16. All rights reserved.
//

import ARKit
import RealityKit
import UIKit

class CameraViewController: UIViewController {
    
    private var recordingManager: RecordingManager! = nil
    
    private let recordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Record", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(.gray, for: .disabled)
        btn.backgroundColor = .systemBlue
        btn.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        initRecordingManagerAndPerformRecordingModeRelatedSetup()
        setupRecordButton()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func initRecordingManagerAndPerformRecordingModeRelatedSetup() {
        
        
        if #available(iOS 14.0, *) {
            recordingManager = ARCameraRecordingManager()
            let session = recordingManager.getSession() as! ARSession
            let arView = ARView()
            arView.session = session
            
            setupPreviewView(previewView: arView)
            navigationItem.title = "Color Camera + LiDAR"
            
        } else {
            print("AR camera only available for iOS 14.0 or newer.")
        }
        
        
    }
    
    private func setupPreviewView(previewView: UIView) {
        // Add the preview view to the main view
        view.addSubview(previewView)
        
        // Disable autoresizing mask translation
        previewView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up aspect ratio constraint (4:3)
        let aspectRatioConstraint = previewView.widthAnchor.constraint(equalTo: previewView.heightAnchor, multiplier: 3.0/4.0)
        aspectRatioConstraint.isActive = true
        
        // Center the preview view within the parent view
        NSLayoutConstraint.activate([
            previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            previewView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        // Temporary background color for debugging (remove this once confirmed)
        previewView.backgroundColor = .black
    }
    
    
    
    private func setupRecordButton() {
        
        view.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8).isActive = true
        
    }
    
    @objc func recordButtonTapped() {
        
        print("Record button tapped")
        
        if recordingManager.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
        
    }
    
    func startRecording() {
        
        recordingManager.startRecording()
        DispatchQueue.main.async {
            self.recordButton.setTitle("Stop", for: .normal)
            self.recordButton.backgroundColor = .systemGray
        }
    }
    
    func stopRecording() {
        
        recordingManager.stopRecording()
        
        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .white
        }
        
    }}
