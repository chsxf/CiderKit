import Foundation
import GameplayKit
import CiderKit_Engine
import Combine

class EditorAssetComponent: GKComponent, Selectable, EditableComponentDelegate {
    
    public var placement: AssetPlacement? { entity?.component(ofType: AssetComponent.self)?.placement }
    
    fileprivate var assetInstance: AssetInstance? { entity?.component(ofType: AssetComponent.self)?.assetInstance }
    
    var placementChangeCancellable: AnyCancellable?
    
    let supportedToolModes: ToolMode = .erase
    
    var inspectableDescription: String { "Asset" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { AssetInspector() })
        view.setObservableObject(placement)
        return view
    }
    
    override init() {
        super.init()
        
        if let placement {
            placementChangeCancellable = placement.objectWillChange.sink {
                if let editableComponent = self.entity?.component(ofType: EditableComponent.self) {
                    editableComponent.invalidate()
                }
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
    
    class func entity(from assetComponentEntity: GKEntity) -> GKEntity {
        let editorAssetComponent = EditorAssetComponent()
        assetComponentEntity.addComponent(editorAssetComponent)
        
        assetComponentEntity.addComponent(EditableComponent(delegate: editorAssetComponent))
        
        return assetComponentEntity
    }
    
}
