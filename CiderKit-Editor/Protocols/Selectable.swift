import GameplayKit

protocol Selectable: Hoverable {
    
    func highlight()
    func demphasize()
    
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
