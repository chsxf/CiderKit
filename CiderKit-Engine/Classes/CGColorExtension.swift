import Foundation
import CoreGraphics
import simd

extension CGColor {
    
    class func interpolateRGB(from: CGColor, to: CGColor, t: Float) -> CGColor? {
        guard let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        
        var convertedFrom: CGColor?
        if from.colorSpace == sRGBColorSpace {
            convertedFrom = from
        }
        else {
            convertedFrom = from.converted(to: sRGBColorSpace, intent: .perceptual, options: nil)
        }
        
        var convertedTo: CGColor?
        if to.colorSpace == sRGBColorSpace {
            convertedTo = to
        }
        else {
            convertedTo = to.converted(to: sRGBColorSpace, intent: .perceptual, options: nil)
        }

        guard let convertedFrom, let convertedTo else { return nil }
        
        let clampedT = simd_clamp(t, 0, 1)
        let tVector = simd_float4(clampedT, clampedT, clampedT, clampedT)
        let fromComponents = convertedFrom.components!
        let fromVector = simd_float4(Float(fromComponents[0]), Float(fromComponents[1]), Float(fromComponents[2]), Float(fromComponents[3]))
        let toComponents = convertedTo.components!
        let toVector = simd_float4(Float(toComponents[0]), Float(toComponents[1]), Float(toComponents[2]), Float(toComponents[3]))
        let interpolatedVector = simd_mix(fromVector, toVector, tVector)
        let interpolatedComponents = [CGFloat(interpolatedVector[0]), CGFloat(interpolatedVector[1]), CGFloat(interpolatedVector[2]), CGFloat(interpolatedVector[3])]
        return CGColor(colorSpace: sRGBColorSpace, components: interpolatedComponents)
    }
    
}
