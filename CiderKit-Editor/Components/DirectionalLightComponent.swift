import Foundation
import GameplayKit
import CiderKit_Engine

class DirectionalLightComponent: GKComponent, Selectable, EditableComponentDelegate, BaseLightComponent {

    let lightImplementation: DirectionalLight
    
    let supportedToolModes: ToolMode = [.move, .erase]
    
    var inspectableDescription: String { "Directional Light" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { DirectionalLightInspector() })
        view.setUpdatableObject(lightImplementation)
        return view
    }

    fileprivate var lightNode: DirectionalLightNode? { entity?.component(ofType: GKSKNodeComponent.self)?.node as? DirectionalLightNode }
    fileprivate var notificationTask: Task<Void, Never>? = nil

    fileprivate init(from lightImplementation: DirectionalLight) {
        self.lightImplementation = lightImplementation
        super.init()
        
        notificationTask = setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationTask?.cancel()
    }

    fileprivate func setupNotifications() -> Task<Void, Never> {
        Task {
            await withThrowingTaskGroup { group in
                group.addTask {
                    for await _ in self.lightImplementation.updated {
                        try Task.checkCancellation()
                        await MainActor.run {
                            if let editableComponent = self.entity?.component(ofType: EditableComponent.self) {
                                editableComponent.invalidate()
                            }
                        }
                    }
                }
            }
        }
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
        Task {
            let newPosition = lightImplementation.position + WorldPosition(x: Float(x), y: Float(y), z: Float(z))
            let newDescription = lightImplementation.description.mutated(withPosition: newPosition)
            await MapModel.shared.update(light: newDescription)
        }
    }
    
}
