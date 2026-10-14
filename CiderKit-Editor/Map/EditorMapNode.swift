import Foundation
import CiderKit_Engine
import GameplayKit

class EditorMapNode: MapNode {

    private var notificationTask: Task<Void, Never>? = nil
    
    private(set) var hoverableEntities: [GKEntity] = []
    
    override init() {
        super.init()
        
        notificationTask = Task {
            await handleNotifications()
        }
    }

    deinit {
        notificationTask?.cancel()
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
    
    override func dismantle(regionNode: MapRegionNode, detach: Bool = true) {
        hoverableEntities.removeAll {
            if let editorMCC = $0.component(ofType: EditorMapCellComponent.self) {
                return editorMCC.region == regionNode
            }

            if let editorAssetComponent = $0.component(ofType: EditorAssetComponent.self), regionNode.regionDescription.contains(assetPlacement: editorAssetComponent.placement.id) {
                editorAssetComponent.unlink()
                return true
            }

            return false
        }

        super.dismantle(regionNode: regionNode, detach: detach)
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
        hoverableEntities.removeAll { $0.component(ofType: EditorMapCellComponent.self) != nil }
    }

    @objc
    private func assetErased(notification: Notification) {
        Task { @MainActor in
            if let assetComponent = notification.object as? EditorAssetComponent {
                NotificationCenter.default.removeObserver(self, name: .selectableErased, object: assetComponent)

                let entity = assetComponent.entity!
                hoverableEntities.removeAll { $0 === entity }

                let assetNode = assetComponent.entity!.component(ofType: GKSKNodeComponent.self)?.node
                assetNode?.removeFromParent()

                await MapModel.shared.removeAsset(withId: assetComponent.placement.id)
            }
        }
    }
    
    private func assetPlacementModified(assetComponent: EditorAssetComponent) async {
        await MapModel.shared.update(assetPlacement: assetComponent.placement.toDescription())
    }
    
    override func createAssetEntity(assetInstance: AssetInstance) -> GKEntity {
        let assetComponentEntity = super.createAssetEntity(assetInstance: assetInstance)
        let entity = EditorAssetComponent.prepareEntity(assetComponentEntity)
        hoverableEntities.append(entity)
        let component = entity.component(ofType: EditorAssetComponent.self)!
        NotificationCenter.default.addObserver(self, selector: #selector(assetErased(notification:)), name: .selectableErased, object: component)
        return entity
    }

    override func remove(assetInstance: AssetInstance) async {
        await super.remove(assetInstance: assetInstance)
        hoverableEntities.removeAll { $0.component(ofType: AssetComponent.self)?.assetInstance === assetInstance }
    }

}
