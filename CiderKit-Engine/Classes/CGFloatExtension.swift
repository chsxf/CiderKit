public extension CGFloat {
    
    static func * (left: CGFloat, right: Float) -> CGFloat {
        return left * CGFloat(right)
    }
    
    static func * (left: CGFloat, right: Double) -> CGFloat {
        return left * CGFloat(right)
    }
    
    static func + (left: CGFloat, right: Float) -> CGFloat {
        return left + CGFloat(right)
    }
    
    static func - (left: CGFloat, right: Float) -> CGFloat {
        return left - CGFloat(right)
    }
    
    static func + (left: CGFloat, right: Double) -> CGFloat {
        return left + CGFloat(right)
    }
    
    static func - (left: CGFloat, right: Double) -> CGFloat {
        return left - CGFloat(right)
    }
    
}
