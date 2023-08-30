import Foundation
import GameplayKit
import CiderKit_Engine
import Combine

class SpriteAssetComponent: GKComponent, Selectable, EditableComponentDelegate {
    
    let placement: SpriteAssetPlacement
    
    var placementChangeCancellable: AnyCancellable?
    
    let supportedToolModes: ToolMode = .erase
    
    var inspectableDescription: String { "Sprite Asset" }
    
    var inspectorView: BaseInspectorView? {
        let view = InspectorViewFactory.getView(forClass: Self.self, generator: { SpriteAssetInspector() })
        view.setObservableObject(placement)
        return view
    }
    
    fileprivate var spriteAssetNode: EditorSpriteAssetNode? { entity?.component(ofType: GKSKNodeComponent.self)?.node as? EditorSpriteAssetNode }
    
    fileprivate init(from placement: SpriteAssetPlacement) {
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
        spriteAssetNode?.selected = true
    }
    
    func demphasize() {
        spriteAssetNode?.selected = false
    }
    
    func hovered() {
        spriteAssetNode?.hovered = true
    }
    
    func departed() {
        spriteAssetNode?.hovered = false
    }
    
    func validate() -> Bool {
        true
    }
    
    func contains(sceneCoordinates: CGPoint) -> Bool {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else { return false }
        let frame = node.calculateAccumulatedFrame()
        return frame.contains(sceneCoordinates)
    }
    
    class func entity(from placement: SpriteAssetPlacement, with node: SpriteAssetNode) -> GKEntity {
        let newEntity = GKEntity();
        
        newEntity.addComponent(GKSKNodeComponent(node: node))
        
        let spriteAssetComponent = SpriteAssetComponent(from: placement)
        newEntity.addComponent(spriteAssetComponent)
        
        newEntity.addComponent(EditableComponent(delegate: spriteAssetComponent))
        
        return newEntity
    }
    
}
