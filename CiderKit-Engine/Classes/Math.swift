import Foundation

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
    
}
