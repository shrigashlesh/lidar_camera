/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View extensions to help with drawing the camera streams correctly on all device orientations.
*/

import SwiftUI

extension View {
    
    func calcAspect(texture: MTLTexture?) -> CGFloat {
        guard let texture = texture else { return 1 }
        return  CGFloat(texture.height) / CGFloat(texture.width)
    }
}
