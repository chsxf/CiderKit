import GameplayKit
import SwiftUI

protocol Selectable: Hoverable {
    
    var supportedToolModes: ToolMode { get }
    var scenePosition: CGPoint { get }
    
    var inspectableDescription: String { get }
    var inspectorView: AnyView { get }
    
    func highlight()
    func demphasize()
    
    func dragBy(x: CGFloat, y: CGFloat, z: CGFloat) -> Void
    
}

extension Selectable {
    
    var supportedToolModes: ToolMode { [] }
    
}

extension Selectable where Self: GKComponent {
    
    var scenePosition: CGPoint {
        get {
            if let node = entity?.component(ofType: GKSKNodeComponent.self)?.node {
                return node.position
            }
            return CGPoint.zero
        }
    }
    
    func dragBy(x: CGFloat, y: CGFloat, z: CGFloat) { }
    
}

extension GKEntity {
    
    func findSelectableComponent() -> Selectable? {
        for component in components {
            if let hoverableComponent = component as? Selectable {
                return hoverableComponent
            }
        }
        return nil
    }
    
}
