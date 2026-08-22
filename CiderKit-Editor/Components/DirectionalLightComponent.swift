import Foundation
import GameplayKit
import CiderKit_Engine
import Combine

class DirectionalLightComponent: GKComponent, Selectable, EditableComponentDelegate {
    
    let lightImplementation: DirectionalLight
    
    var lightImplementationChangeCancellable: AnyCancellable?
    
    let supportedToolModes: ToolMode = [.move, .erase]
    
    var inspectableDescription: String { "Directional Light" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { DirectionalLightInspector() })
        view.setObservableObject(lightImplementation)
        return view
    }
    
    fileprivate var lightNode: DirectionalLightNode? { entity?.component(ofType: GKSKNodeComponent.self)?.node as? DirectionalLightNode }
    
    fileprivate init(from lightImplementation: DirectionalLight) {
        self.lightImplementation = lightImplementation
        super.init()
        
        lightImplementationChangeCancellable = self.lightImplementation.objectWillChange.sink {
            if let editableComponent = self.entity?.component(ofType: EditableComponent.self) {
                editableComponent.invalidate()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contains(sceneCoordinates: ScenePosition) -> Bool {
        guard let lightNode = lightNode else { return false }
        let frame = lightNode.calculateAccumulatedFrame()
        return frame.contains(sceneCoordinates)
    }

    func hovered() {
        lightNode?.hovered = true
    }
    
    func departed() {
        lightNode?.hovered = false
    }
    
    func highlight() {
        lightNode?.selected = true
    }
    
    func deemphasize() {
        lightNode?.selected = false
    }
    
    class func entity(from lightImplementation: DirectionalLight) -> GKEntity {
        let newEntity = GKEntity();
        
        let scenePosition = MapNode.worldToScene(lightImplementation.position)

        let directionalLight = DirectionalLightNode()
        directionalLight.position = scenePosition
        directionalLight.enabled = lightImplementation.enabled
        directionalLight.setLightColor(lightImplementation.color)
        newEntity.addComponent(GKSKNodeComponent(node: directionalLight))
        
        let directionalLightComponent = DirectionalLightComponent(from: lightImplementation)
        newEntity.addComponent(directionalLightComponent)
        
        newEntity.addComponent(EditableComponent(delegate: directionalLightComponent))
        
        return newEntity
    }
    
    func validate() -> Bool {
        guard let directionalLight = lightNode else {
            return false
        }
        
        directionalLight.position = MapNode.worldToScene(lightImplementation.position)
        directionalLight.enabled = lightImplementation.enabled
        directionalLight.setLightColor(lightImplementation.color)
        
        return true
    }
    
    func dragBy(x: CGFloat, y: CGFloat, z: CGFloat) {
        lightImplementation.position += WorldPosition(x: Float(x), y: Float(y), z: Float(z))
        entity?.component(ofType: EditableComponent.self)?.invalidate()
    }
    
}
