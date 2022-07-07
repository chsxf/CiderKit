import GameplayKit
import SwiftUI

protocol Selectable: Hoverable {
    
    var inspectableDescription: String { get }
    var inspectorView: AnyView { get }
    
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
