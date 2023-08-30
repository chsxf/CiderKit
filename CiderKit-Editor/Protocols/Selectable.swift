import GameplayKit

extension Notification.Name {
    static let selectableErased = Notification.Name(rawValue: "selectableErased")
}

protocol Selectable: Hoverable {
    
    var supportedToolModes: ToolMode { get }
    var scenePosition: CGPoint { get }
    
    var inspectableDescription: String { get }
    var inspectorView: BaseInspectorView? { get }
    
    func highlight()
    func demphasize()
    
    func dragBy(x: CGFloat, y: CGFloat, z: CGFloat) -> Void
    func erase() -> Void
    
}

extension Selectable where Self: GKComponent {
    
    var supportedToolModes: ToolMode { [] }
    
    var scenePosition: CGPoint {
        get {
            if let node = entity?.component(ofType: GKSKNodeComponent.self)?.node {
                return node.position
            }
            return CGPoint.zero
        }
    }
    
    func dragBy(x: CGFloat, y: CGFloat, z: CGFloat) { }
    
    func erase() {
        NotificationCenter.default.post(name: .selectableErased, object: self)
    }
    
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
