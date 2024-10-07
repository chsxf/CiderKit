import Foundation
import CoreGraphics

extension CGMutablePath {
    
    public func move(to point: SIMD2<Float>) {
        self.move(to: point.toCGPoint())
    }
    
    public func addLine(to point: SIMD2<Float>) {
        self.addLine(to: point.toCGPoint())
    }
    
}
