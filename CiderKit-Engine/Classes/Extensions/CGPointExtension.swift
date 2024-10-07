import CoreGraphics

public extension CGPoint {
    
    init(x: Float, y: Float) {
        self.init(x: CGFloat(x), y: CGFloat(y))
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    func toSIMDFloat2() -> SIMD2<Float> {
        SIMD2<Float>(Float(self.x), Float(self.y))
    }
    
    func toSIMDFloat3() -> SIMD3<Float> {
        SIMD3<Float>(Float(self.x), Float(self.y), 0)
    }
    
}
