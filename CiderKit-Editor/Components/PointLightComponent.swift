import Foundation
import GameplayKit
import CiderKit_Engine

class PointLightComponent: GKComponent, Selectable, EditableComponentDelegate, BaseLightComponent {
    
    let lightImplementation: PointLight

    let supportedToolModes: ToolMode = [.move, .erase]
    
    var inspectableDescription: String { "Point Light" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { PointLightInspector() })
        view.setUpdatableObject(lightImplementation)
        return view
    }

    private var notificationTask: Task<Void, Never>? = nil

    fileprivate var lightNode: PointLightNode? { entity?.component(ofType: GKSKNodeComponent.self)?.node as? PointLightNode }
    
    fileprivate init(from lightImplementation: PointLight) {
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

    private func setupNotifications() -> Task<Void, Never> {
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
    
    class func entity(from lightImplementation: PointLight) -> GKEntity {
        let newEntity = GKEntity();
        
        let scenePosition = MapNode.worldToScene(lightImplementation.position)

        let pointLight = PointLightNode()
        pointLight.position = scenePosition
        pointLight.enabled = lightImplementation.enabled
        pointLight.setLightColor(lightImplementation.color)
        newEntity.addComponent(GKSKNodeComponent(node: pointLight))
        
        let pointLightComponent = PointLightComponent(from: lightImplementation)
        newEntity.addComponent(pointLightComponent)
        
        newEntity.addComponent(EditableComponent(delegate: pointLightComponent))
        
        return newEntity
    }

    @discardableResult
    func validate() -> Bool {
        guard let pointLight = lightNode else {
            return false
        }
        
        pointLight.position = MapNode.worldToScene(lightImplementation.position)
        pointLight.enabled = lightImplementation.enabled
        pointLight.setLightColor(lightImplementation.color)

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
