import GameplayKit
import CiderKit_Engine

protocol Tool: Hoverable {
    
    var linkedSelectable: Selectable? { get set }
    
    var enabled: Bool { get set }
    var interactedWith: Bool { get }
    
    func moveTo(scenePosition: ScenePosition) -> Void

    func dragInScene(bySceneX x: CGFloat, y: CGFloat) -> Void
    func mouseUp(atSceneX x: CGFloat, y: CGFloat) -> Void
}

extension Tool where Self: GKComponent {
    
    func moveTo(scenePosition: ScenePosition) -> Void {
        if let node = entity?.component(ofType: GKSKNodeComponent.self)?.node {
            node.position = scenePosition
        }
    }
    
}

extension GKEntity {

    func findTool() -> Tool? {
        for component in components {
            if let tool = component as? Tool {
                return tool
            }
        }
        return nil
    }
    
}
