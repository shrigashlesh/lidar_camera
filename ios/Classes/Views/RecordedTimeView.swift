//
//  RecordedTimeView.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import UIKit

class RecordedTimeView: UIView {
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Set padding by adjusting the constraints
        let padding: CGFloat = 8 // Define the padding
        
        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
        
        layer.cornerRadius = 8
    }
    
    // MARK: - Public Methods
    func updateTime(positionalTime: String, isRecording: Bool) {
        timeLabel.text = positionalTime
        backgroundColor = isRecording ? UIColor.red.withAlphaComponent(0.8) : nil
    }
}
