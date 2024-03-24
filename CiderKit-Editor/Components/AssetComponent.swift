import Foundation
import GameplayKit
import CiderKit_Engine
import Combine

class AssetComponent: GKComponent, Selectable, EditableComponentDelegate {
    
    let placement: AssetPlacement
    
    var placementChangeCancellable: AnyCancellable?
    
    let supportedToolModes: ToolMode = .erase
    
    var inspectableDescription: String { "Asset" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { AssetInspector() })
        view.setObservableObject(placement)
        return view
    }
    
    fileprivate var assetInstance: AssetInstance? = nil
    
    fileprivate init(from placement: AssetPlacement) {
        self.placement = placement
        super.init()
        
        placementChangeCancellable = self.placement.objectWillChange.sink {
            if let editableComponent = self.entity?.component(ofType: EditableComponent.self) {
                editableComponent.invalidate()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func highlight() {
        NotificationCenter.default.post(name: .selectableHighlighted, object: assetInstance)
    }
    
    func deemphasize() {
        NotificationCenter.default.post(name: .selectableDeemphasized, object: assetInstance)
    }
    
    func hovered() {
        NotificationCenter.default.post(name: .hoverableHovered, object: assetInstance)
    }
    
    func departed() {
        NotificationCenter.default.post(name: .hoverableDeparted, object: assetInstance)
    }
    
    func validate() -> Bool {
        true
    }
    
    func contains(sceneCoordinates: CGPoint) -> Bool {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else { return false }
        let frame = node.calculateAccumulatedFrame()
        return frame.contains(sceneCoordinates)
    }
    
    class func entity(from placement: AssetPlacement, with instance: AssetInstance) -> GKEntity {
        let newEntity = GKEntity();
        
        newEntity.addComponent(GKSKNodeComponent(node: instance.node!))
        
        let assetComponent = AssetComponent(from: placement)
        assetComponent.assetInstance = instance
        newEntity.addComponent(assetComponent)
        
        newEntity.addComponent(EditableComponent(delegate: assetComponent))
        
        return newEntity
    }
    
}
