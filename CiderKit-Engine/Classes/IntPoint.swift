public typealias IntPoint = SIMD2<Int>

public extension IntPoint {
    
    static let zero = IntPoint(0, 0)
    static let one = IntPoint(1, 1)
    
    static let down = IntPoint(0, -1)
    static let downLeft = IntPoint(-1, -1)
    static let downRight = IntPoint(1, -1)
    static let left = IntPoint(-1, 0)
    static let right = IntPoint(1, 0)
    static let up = IntPoint(0, 1)
    static let upLeft = IntPoint(-1, 1)
    static let upRight = one
    
}
