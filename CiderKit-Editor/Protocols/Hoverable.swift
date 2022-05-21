import CoreGraphics
import GameplayKit

protocol Hoverable {
    
    var entity: GKEntity? { get }
    
    func contains(sceneCoordinates: CGPoint) -> Bool
    func hovered()
    func departed()
    
}

extension GKEntity {
    
    func findHoverableComponent() -> Hoverable? {
        for component in components {
            if let hoverableComponent = component as? Hoverable {
                return hoverableComponent
            }
        }
        return nil
    }
    
}
