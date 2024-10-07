import Foundation
import CoreGraphics

extension SIMD2 {

    public mutating func flip() {
        let buffer = self.y
        self.y = self.x
        self.x = buffer
    }

    public func flipped() -> SIMD2 {
        SIMD2(self.y, self.x)
    }

}

extension SIMD2<Float> {

    public func toCGPoint() -> CGPoint { CGPoint(x: CGFloat(self.x), y: CGFloat(self.y)) }

}

extension SIMD3 {
    
    public init(_ vector: SIMD4<Scalar>) {
        self.init(vector.x, vector.y, vector.z)
    }
    
}

extension SIMD3<Float> {

    public init(_ vector: SIMD2<Float>) {
        self.init(vector.x, vector.y, 0)
    }

}

extension SIMD4 {

    public init(_ vector: SIMD3<Scalar>, _ scalar: Scalar) {
        self.init(vector.x, vector.y, vector.z, scalar)
    }

}
