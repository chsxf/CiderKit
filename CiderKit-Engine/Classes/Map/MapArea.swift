import Foundation
import CoreGraphics

public struct MapArea: Equatable, CustomStringConvertible, Sendable {
    
    public var x: Int
    public var y: Int
    
    public var width: Int
    public var height: Int
    
    public var minX: Int { x }
    public var maxX: Int { x + width }
    
    public var minY: Int { y }
    public var maxY: Int { y + height }
    
    public var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
    
    public var description: String { "MapArea(x: \(x), y: \(y), w: \(width), h: \(height))" }
    
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
    
    public func contains(absolute other: MapArea) -> Bool {
        return minX <= other.minX && maxX >= other.maxX && minY <= other.minY && maxY >= other.maxY
    }
    
    public func contains(mapX x: Int, y: Int) -> Bool {
        return x >= self.x && x < maxX && y >= self.y && y < maxY
    }

    public func contains(mapPosition position: MapPosition) -> Bool {
        return contains(mapX: position.x, y: position.y)
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
    
    public func relative(to area: MapArea) -> MapArea {
        return MapArea(x: self.x - area.x, y: self.y - area.y, width: self.width, height: self.height)
    }
    
    public func convert(fromMapPoint point: IntPoint) -> IntPoint { convert(fromMapX: point.x, y: point.y) }
    public func convert(fromMapX x: Int, y: Int) -> IntPoint { IntPoint(x: x - self.x, y: y - self.y) }
    public func convert(fromMapPosition position: MapPosition) -> IntPoint { convert(fromMapX: position.x, y: position.y) }

    public func convert(fromLocalPoint point: IntPoint) -> IntPoint { convert(fromLocalX: point.x, y: point.y) }
    public func convert(fromLocalX x: Int, y: Int) -> IntPoint { IntPoint(x: x + self.x, y: y + self.y) }
    public func convert(fromLocalPosition position: MapPosition) -> IntPoint { convert(fromLocalX: position.x, y: position.y) }

}
