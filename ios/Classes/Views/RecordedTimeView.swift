//
//  RecordedTimeView.swift
//  lidar_camera
//
//  Created by Shrig Solutions on 17/09/2024.
//

import Foundation
import SwiftUI

struct RecordedTimeView: View {
    var positionalTime: String
    var isRecording: Bool

    var body: some View {
        Text(positionalTime)
            .padding(4)
            .background(isRecording ? Color.red : Color.black)
            .foregroundColor(Color.white)
            .cornerRadius(8)
    }
}
