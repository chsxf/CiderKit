import Foundation
import CoreGraphics

extension SIMD2<Float> {
    
    public func toCGPoint() -> CGPoint { CGPoint(x: CGFloat(self.x), y: CGFloat(self.y)) }
    
}
