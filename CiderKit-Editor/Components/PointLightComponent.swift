import Foundation
import GameplayKit
import CiderKit_Engine
import Combine

class PointLightComponent: GKComponent, Selectable, EditableComponentDelegate {
    
    let lightDescription: PointLight
    
    var lightDescriptionChangeCancellable: AnyCancellable?
    
    let supportedToolModes: ToolMode = [.move, .erase]
    
    var inspectableDescription: String { "Point Light" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { PointLightInspector() })
        view.setObservableObject(lightDescription)
        return view
    }
    
    fileprivate var lightNode: PointLightNode? { entity?.component(ofType: GKSKNodeComponent.self)?.node as? PointLightNode }
    
    fileprivate init(from lightDescription: PointLight) {
        self.lightDescription = lightDescription
        super.init()
        
        lightDescriptionChangeCancellable = self.lightDescription.objectWillChange.sink {
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
    
    class func entity(from lightDescription: PointLight) -> GKEntity {
        let newEntity = GKEntity();
        
        let scenePosition = MapNode.worldToScene(lightDescription.position)

        let pointLight = PointLightNode()
        pointLight.position = scenePosition
        pointLight.enabled = lightDescription.enabled
        pointLight.setLightColor(lightDescription.color)
        newEntity.addComponent(GKSKNodeComponent(node: pointLight))
        
        let pointLightComponent = PointLightComponent(from: lightDescription)
        newEntity.addComponent(pointLightComponent)
        
        newEntity.addComponent(EditableComponent(delegate: pointLightComponent))
        
        return newEntity
    }
    
    func validate() -> Bool {
        guard let pointLight = lightNode else {
            return false
        }
        
        pointLight.position = MapNode.worldToScene(lightDescription.position)
        pointLight.enabled = lightDescription.enabled
        pointLight.setLightColor(lightDescription.color)
        
        return true
    }
    
    func dragBy(x: CGFloat, y: CGFloat, z: CGFloat) {
        lightDescription.position += WorldPosition(x: Float(x), y: Float(y), z: Float(z))
        entity?.component(ofType: EditableComponent.self)?.invalidate()
    }
    
}
