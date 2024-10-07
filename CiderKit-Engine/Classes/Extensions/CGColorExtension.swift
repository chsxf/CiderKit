import Foundation
import CoreGraphics
import simd

extension CGColor {
    
    public func toRGB() -> CGColor? {
        guard let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        
        if self.colorSpace == sRGBColorSpace {
            return self
        }
        else {
            return self.converted(to: sRGBColorSpace, intent: .perceptual, options: nil)
        }
    }
    
    class func interpolateRGB(from: CGColor, to: CGColor, t: Float) -> CGColor? {
        guard
            let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let convertedFrom = from.toRGB(),
            let convertedTo = to.toRGB()
        else { return nil }
        
        let clampedT = simd_clamp(t, 0, 1)
        let tVector = SIMD4<Float>(clampedT, clampedT, clampedT, clampedT)
        let fromComponents = convertedFrom.components!
        let fromVector = SIMD4<Float>(Float(fromComponents[0]), Float(fromComponents[1]), Float(fromComponents[2]), Float(fromComponents[3]))
        let toComponents = convertedTo.components!
        let toVector = SIMD4<Float>(Float(toComponents[0]), Float(toComponents[1]), Float(toComponents[2]), Float(toComponents[3]))
        let interpolatedVector = simd_mix(fromVector, toVector, tVector)
        let interpolatedComponents = [CGFloat(interpolatedVector[0]), CGFloat(interpolatedVector[1]), CGFloat(interpolatedVector[2]), CGFloat(interpolatedVector[3])]
        return CGColor(colorSpace: sRGBColorSpace, components: interpolatedComponents)
    }

    public class func randomRGB(a: CGFloat = 1) -> CGColor {
        return CGColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: a)
    }

}
