import Foundation
import CiderKit_Engine
import GameplayKit

extension Notification.Name {
    static let mapDirtyStatusChanged = Self.init(rawValue: "mapDirtyStatusChanged")
}

class EditorMapNode: MapNode {

    private var notificationTask: Task<Void, Never>? = nil
    
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
        
        notificationTask = Task {
            await handleNotifications()
        }
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleNotifications() async {
        for await assetComponent in NotificationCenter.default.notifications(named: .assetPlacementModified)
                                                                .compactMap({ $0.object as? EditorAssetComponent }) {
            await assetPlacementModified(assetComponent: assetComponent)
        }
    }
    
    override func onModelChanged(_ changedModel: MapModel) {
        super.onModelChanged(changedModel)
        Task {
            await MainActor.run {
                dirty = true
            }
        }
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
        Task { @MainActor in
            if let assetComponent = notification.object as? EditorAssetComponent {
                NotificationCenter.default.removeObserver(self, name: .selectableErased, object: assetComponent)

                let entity = assetComponent.entity!
                cleanHoverableEntities { $0 === entity }

                let assetNode = assetComponent.entity!.component(ofType: GKSKNodeComponent.self)?.node
                assetNode?.removeFromParent()

                await model?.removeAsset(withId: assetComponent.placement.id)

                dirty = true
            }
        }
    }
    
    private func assetPlacementModified(assetComponent: EditorAssetComponent) async {
        await model?.update(assetPlacement: assetComponent.placement.toDescription())
        dirty = true
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
