import CoreGraphics
import CiderKit_Engine
import GameplayKit

extension Notification.Name {
    
    static let hoverableHovered = Self.init(rawValue: "hoverableHovered")
    static let hoverableDeparted = Self.init(rawValue: "hoverableDeparted")
    
}

protocol Hoverable: AnyObject {
    
    var entity: GKEntity? { get }
    
    func contains(sceneCoordinates: ScenePosition) -> Bool
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
