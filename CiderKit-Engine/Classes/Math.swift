import Foundation
import CoreGraphics

public final class Math {
    
    public static func sceneToWorld(_ point: CGPoint, halfTileSize: CGSize) -> CGPoint {
        let xWorld = ((point.x / halfTileSize.width) - (point.y / halfTileSize.height)) / 2
        let yWorld = -(point.y / halfTileSize.height) - xWorld
        return CGPoint(x: xWorld, y: yWorld)
    }
    
    public static func worldToScene(_ point: CGPoint, halfTileSize: CGSize) -> CGPoint {
        let xScene = halfTileSize.width * (point.x - point.y)
        let yScene = -halfTileSize.height * (point.x + point.y)
        return CGPoint(x: xScene, y: yScene)
    }
    
    public static func sceneToCell(_ point: CGPoint, halfTileSize: CGSize) -> CGPoint {
        let world = sceneToWorld(point, halfTileSize: halfTileSize)
        return worldToCell(world)
    }
    
    public static func cellToScene(_ point: CGPoint, halfTileSize: CGSize) -> CGPoint {
        return worldToScene(point, halfTileSize: halfTileSize)
    }
    
    public static func worldToCell(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x.rounded(.down), y: point.y.rounded(.down))
    }
    
    public static func cellToWorld(_ point: CGPoint) -> CGPoint {
        return point
    }
}
