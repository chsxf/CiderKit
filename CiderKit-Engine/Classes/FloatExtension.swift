public extension Float {
    
    func toDegrees() -> Float {
        return self * 180.0 / .pi
    }
    
    func toRadians() -> Float {
        return self * .pi / 180.0
    }
    
}
