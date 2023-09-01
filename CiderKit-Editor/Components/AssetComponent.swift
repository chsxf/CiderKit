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
    
    fileprivate var assetInstance: EditorAssetInstance? = nil
    
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
        assetInstance?.selected = true
    }
    
    func demphasize() {
        assetInstance?.selected = false
    }
    
    func hovered() {
        assetInstance?.hovered = true
    }
    
    func departed() {
        assetInstance?.hovered = false
    }
    
    func validate() -> Bool {
        true
    }
    
    func contains(sceneCoordinates: CGPoint) -> Bool {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else { return false }
        let frame = node.calculateAccumulatedFrame()
        return frame.contains(sceneCoordinates)
    }
    
    class func entity(from placement: AssetPlacement, with instance: EditorAssetInstance) -> GKEntity {
        let newEntity = GKEntity();
        
        newEntity.addComponent(GKSKNodeComponent(node: instance.node!))
        
        let assetComponent = AssetComponent(from: placement)
        assetComponent.assetInstance = instance
        newEntity.addComponent(assetComponent)
        
        newEntity.addComponent(EditableComponent(delegate: assetComponent))
        
        return newEntity
    }
    
}
