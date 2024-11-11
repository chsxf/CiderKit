import Foundation
import CiderKit_Engine
import GameplayKit

extension Notification.Name {
    static let mapDirtyStatusChanged = Self.init(rawValue: "mapDirtyStatusChanged")
}

class EditorMapNode: MapNode {

    var dirty: Bool = false {
        didSet {
            if dirty != oldValue {
                NotificationCenter.default.post(Notification(name: .mapDirtyStatusChanged))
            }
        }
    }
    
    private(set) var hoverableEntities: [GKEntity] = []
    
    override init(with model: MapModel) {
        super.init(with: model)
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func onModelChanged(_ changedModel: MapModel) {
        super.onModelChanged(changedModel)
        dirty = true
    }

    override func rebuildRegionNodes() {
        removeHoverableMapCellEntities()
        super.rebuildRegionNodes()
    }

    override func mapCellEntity(node: SKNode, for region: MapRegionNode, atMapPosition position: MapPosition) -> GKEntity {
        let entity = super.mapCellEntity(node: node, for: region, atMapPosition: position)
        hoverableEntities.append(entity)
        return entity
    }

    override func mapCellComponent(for region: MapRegionNode, atMapPosition position: MapPosition) -> MapCellComponent {
        return EditorMapCellComponent(region: region, position: position)
    }
    
    func removeHoverableMapCellEntities() {
        cleanHoverableEntities { $0.component(ofType: EditorMapCellComponent.self) != nil }
    }

    @objc
    private func assetErased(notification: Notification) {
        if let assetComponent = notification.object as? EditorAssetComponent {
            NotificationCenter.default.removeObserver(self, name: .selectableErased, object: assetComponent)
            
            let entity = assetComponent.entity!
            cleanHoverableEntities { $0 === entity }

            let assetNode = assetComponent.entity!.component(ofType: GKSKNodeComponent.self)?.node
            assetNode?.removeFromParent()

            model?.removeAsset(with: assetComponent.placement.id)

            dirty = true
        }
    }
    
    override func createAssetEntity(assetInstance: AssetInstance) -> GKEntity {
        let assetComponentEntity = super.createAssetEntity(assetInstance: assetInstance)
        let entity = EditorAssetComponent.prepareEntity(assetComponentEntity)
        hoverableEntities.append(entity)
        let component = entity.component(ofType: EditorAssetComponent.self)!
        NotificationCenter.default.addObserver(self, selector: #selector(assetErased(notification:)), name: .selectableErased, object: component)
        return entity
    }

    override func remove(assetInstance: AssetInstance, includingPlacement: Bool = true) {
        super.remove(assetInstance: assetInstance, includingPlacement: includingPlacement)
        cleanHoverableEntities { $0.component(ofType: AssetComponent.self)?.assetInstance === assetInstance }
    }

    private func cleanHoverableEntities(where predicate: (GKEntity) -> Bool) {
        hoverableEntities.removeAll {
            let editorAssetComponent = $0.component(ofType: EditorAssetComponent.self)
            if predicate($0) {
                editorAssetComponent?.unlink()
                return true
            }
            return false
        }
    }

}
