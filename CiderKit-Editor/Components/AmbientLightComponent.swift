import GameplayKit
import CiderKit_Engine

class AmbientLightComponent: GKComponent, Selectable, EditableComponentDelegate {
    
    let lightImplementation: AmbientLight
    
    var inspectableDescription: String { "Ambient Light" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { AmbientLightInspector() })
        view.setUpdatableObject(lightImplementation)
        return view
    }

    fileprivate var notificationTask: Task<Void, Never>? = nil

    fileprivate init(from lightImplementation: AmbientLight) {
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

    func highlight() { }
    
    func deemphasize() { }
    
    func contains(sceneCoordinates: ScenePosition) -> Bool { false }
    
    func hovered() { }
    
    func departed() { }
    
    func validate() -> Bool {
        return true
    }
    
    class func entity(from lightImplementation: AmbientLight) -> GKEntity {
        let newEntity = GKEntity();
        
        let ambientLightComponent = AmbientLightComponent(from: lightImplementation)
        newEntity.addComponent(ambientLightComponent)
        
        newEntity.addComponent(EditableComponent(delegate: ambientLightComponent))
        
        return newEntity
    }
    
}
