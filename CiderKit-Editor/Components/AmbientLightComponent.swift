import GameplayKit
import CiderKit_Engine
import Combine

class AmbientLightComponent: GKComponent, Selectable, EditableComponentDelegate {
    
    let lightDescription: BaseLight
    
    var lightDescriptionChangeCancellable: AnyCancellable?
    
    var inspectableDescription: String { "Ambient Light" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { AmbientLightInspector() })
        view.setObservableObject(lightDescription)
        return view
    }
    
    fileprivate init(from lightDescription: BaseLight) {
        self.lightDescription = lightDescription
        super.init()
        
        lightDescriptionChangeCancellable = self.lightDescription.objectWillChange.sink {
            if let editable = self.entity?.component(ofType: EditableComponent.self) {
                editable.invalidate()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func highlight() { }
    
    func deemphasize() { }
    
    func contains(sceneCoordinates: ScenePosition) -> Bool { false }
    
    func hovered() { }
    
    func departed() { }
    
    func validate() -> Bool {
        return true
    }
    
    class func entity(from lightDescription: BaseLight) -> GKEntity {
        let newEntity = GKEntity();
        
        let ambientLightComponent = AmbientLightComponent(from: lightDescription)
        newEntity.addComponent(ambientLightComponent)
        
        newEntity.addComponent(EditableComponent(delegate: ambientLightComponent))
        
        return newEntity
    }
    
}
