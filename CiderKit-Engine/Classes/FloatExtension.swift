public extension Float {
    
    func toDegrees() -> Float {
        return self * 180.0 / .pi
    }
    
    func toRadians() -> Float {
        return self * .pi / 180.0
    }
    
    static func * (left: Float, right: CGFloat) -> Float {
        return left * Float(right)
    }
    
    static func - (left: Float, right: CGFloat) -> Float {
        return left - Float(right)
    }
    
    static func + (left: Float, right: CGFloat) -> Float {
        return left + Float(right)
    }
    
}
