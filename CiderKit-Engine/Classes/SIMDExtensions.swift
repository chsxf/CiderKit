import Foundation
import CoreGraphics

extension SIMD2<Float> {
    
    public func toCGPoint() -> CGPoint { CGPoint(x: CGFloat(self.x), y: CGFloat(self.y)) }
    
}

extension SIMD4<Float> {
    
    public init(_ vector: SIMD3<Float>, _ scalar: Float) {
        self.init(vector.x, vector.y, vector.z, scalar)
    }
    
}

extension SIMD3<Float> {
    
    public init(_ vector: SIMD4<Float>) {
        self.init(vector.x, vector.y, vector.z)
    }
    
}
