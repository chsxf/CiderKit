import Foundation

public struct MapArea: Equatable {
    
    public var x: Int
    public var y: Int
    
    public var width: Int
    public var height: Int
    
    public var minX: Int { x }
    public var maxX: Int { x + width }
    
    public var minY: Int { y }
    public var maxY: Int { y + height }
    
    public var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    public init(from rect: CGRect) {
        let integral = rect.integral
        self.init(x: Int(integral.minX), y: Int(integral.minY), width: Int(integral.width), height: Int(integral.height))
    }
    
    public func contains(_ other: MapArea) -> Bool {
        return minX <= other.minX && maxX >= other.maxX && minY <= other.minY && maxY >= other.maxY
    }
    
    public func intersects(_ other: MapArea) -> Bool {
        let overlapsOnX = (maxX > other.minX && minX < other.maxX)
        let overlapsOnY = (maxY > other.minY && minY < other.maxY)
        return overlapsOnX && overlapsOnY
    }
    
    public func intersection(_ other: MapArea) -> MapArea? {
        var intersectionArea: MapArea? = nil
        
        if intersects(other) {
            let newX = max(x, other.x)
            let newY = max(y, other.y)
            let newWidth = min(maxX, other.maxX) - newX
            let newHeight = min(maxY, other.maxY) - newY
            intersectionArea = MapArea(x: newX, y: newY, width: newWidth, height: newHeight)
        }
        
        return intersectionArea
    }
    
}
