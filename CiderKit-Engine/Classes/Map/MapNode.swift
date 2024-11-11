import SpriteKit
import Combine
import GameplayKit

open class MapNode: SKNode {
    
    nonisolated public static let elevationHeight: Int = 10

    nonisolated public static let tileWidth: Int = 48
    nonisolated public static let tileHeight: Int = 24
    nonisolated public static let tileSize = CGSize(width: CGFloat(MapNode.tileWidth), height: CGFloat(MapNode.tileHeight))

    nonisolated public static let halfWidth: Int = MapNode.tileWidth / 2
    nonisolated public static let halfHeight: Int = MapNode.tileHeight / 2
    nonisolated public static let halfTileSize = CGSize(width: CGFloat(MapNode.halfWidth), height: CGFloat(MapNode.halfHeight))

    nonisolated public static let xVector = SIMD2(Float(MapNode.halfWidth), Float(-MapNode.halfHeight))
    nonisolated public static let yVector = SIMD2(Float(-MapNode.halfWidth), Float(-MapNode.halfHeight))
    nonisolated public static let zVector = SIMD2(0, Float(MapNode.elevationHeight))

    public private(set) weak var model: MapModel? = nil
    private var modelCancellable: AnyCancellable!

    public private(set) var assetEntities: [GKEntity] = []
    public let assetComponentSystem: GKComponentSystem<AssetComponent>
    
    private var nodesByRegionId = [Int:MapRegionNode]()
    private var orderedRegionNodes = [MapRegionNode]()
    
    public init(with model: MapModel) {
        self.model = model
        assetComponentSystem = GKComponentSystem(componentClass: AssetComponent.self)
        
        super.init()
        
        registerCellRenderers()
        rebuildRegionNodes()
        
        zPosition = 2

        modelCancellable = model.changed.sink(receiveValue: self.onModelChanged(_:))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func onModelChanged(_ changedModel: MapModel) {
        rebuildRegionNodes()
    }

    private func registerCellRenderers() {
        if let model {
            for (name, rendererDescription) in model.cellRenderers {
                let renderer = CellRenderer(from: rendererDescription)
                try! CellRenderers.register(cellRenderer: renderer, named: name)
            }
        }
    }
    
    open func rebuildRegionNodes() {
        if let model {
            orderedRegionNodes.forEach { $0.dismantle() }
            orderedRegionNodes.removeAll()
            
            var idsToRemove = Array(nodesByRegionId.keys)
            
            for regionModel in model.regions {
                if idsToRemove.contains(regionModel.id) {
                    idsToRemove.removeAll { $0 == regionModel.id }
                }
                else {
                    let regionNode = MapRegionNode(for: regionModel)
                    nodesByRegionId[regionModel.id] = regionNode
                    addChild(regionNode)
                }
                
                if let node = nodesByRegionId[regionModel.id] {
                    orderedRegionNodes.append(node)
                }
            }
            
            for idToRemove in idsToRemove {
                if let node = nodesByRegionId.removeValue(forKey: idToRemove) {
                    node.removeFromParent()
                }
            }
            
            orderedRegionNodes.forEach { $0.build() }
            
            updateRegionsZPosition()
        }
    }
    
    private func updateRegionsZPosition() {
        var index = 0
        for regionNode in orderedRegionNodes {
            regionNode.zPosition = CGFloat(index)
            index += regionNode.layerCount
        }
    }
    
    public func regionNode(atMapX x: Int, y: Int) -> MapRegionNode? {
        if let regionModel = model?.regionAt(mapX: x, y: y) {
            return nodesByRegionId[regionModel.id]
        }
        return nil
    }

    public func regionNode(at position: MapPosition) -> MapRegionNode? { regionNode(atMapX: position.x, y: position.y) }

    public func lookForMapCellEntity(at position: MapPosition) -> GKEntity? {
        if let regionNode = regionNode(at: position) {
            for cell in regionNode.cellEntities {
                for component in cell.components {
                    if let cellComponent = component as? MapCellComponent {
                        if cellComponent.position.x == position.x && cellComponent.position.y == position.y {
                            return cell
                        }
                        break
                    }
                }
            }
        }
        return nil
    }
    
    public func raycastMapCell(at sceneCoordinates: ScenePosition) -> MapCellComponent? {
        for regionNode in orderedRegionNodes {
            for cell in regionNode.cellEntities {
                if let cellComponent = cell.component(ofType: MapCellComponent.self), cellComponent.contains(sceneCoordinates: sceneCoordinates){
                    return cellComponent
                }
            }
        }
        return nil
    }

    public func raycastWorldPosition(at sceneCoordinates: ScenePosition) -> WorldPosition? {
        for regionNode in orderedRegionNodes {
            for cell in regionNode.cellEntities {
                if let containedWorldPosition = cell.component(ofType: MapCellComponent.self)?.getContainedWorldPosition(sceneCoordinates: sceneCoordinates) {
                    return containedWorldPosition
                }
            }
        }
        return nil
    }

    public func raycastAsset(at sceneCoordinates: ScenePosition) -> AssetComponent? {
        assetComponentSystem.components.first(where: { $0.contains(sceneCoordinates: sceneCoordinates) && ($0.assetInstance?.interactive ?? false) })
    }

    public func raycastAny(at sceneCoordinates: ScenePosition) -> GKComponent? {
        raycastAsset(at: sceneCoordinates) ?? raycastMapCell(at: sceneCoordinates)
    }

    open func mapCellEntity(node: SKNode, for region: MapRegionNode, atMapPosition position: MapPosition) -> GKEntity {
        let entity = GKEntity()
        entity.addComponent(GKSKNodeComponent(node: node))
        let cell = mapCellComponent(for: region, atMapPosition: position)
        entity.addComponent(cell)
        return entity
    }
    
    open func mapCellComponent(for region: MapRegionNode, atMapPosition position: MapPosition) -> MapCellComponent {
        return MapCellComponent(region: region, position: position)
    }
    
    public final func instantiateAsset(placement: AssetPlacement) -> (AssetInstance, GKEntity)? {
        guard let instance = AssetInstance(placement: placement) else { return nil }
        return (instance, createAssetEntity(assetInstance: instance))
    }
    
    open func createAssetEntity(assetInstance: AssetInstance) -> GKEntity {
        let entity = AssetComponent.entity(with: assetInstance)
        assetComponentSystem.addComponent(foundIn: entity)
        assetEntities.append(entity)
        return entity
    }

    open func remove(assetInstance: AssetInstance, includingPlacement: Bool = true) {
        var foundComponent: AssetComponent? = nil
        for component in assetComponentSystem.components {
            if component.assetInstance === assetInstance {
                foundComponent = component
                break
            }
        }

        if let foundComponent {
            let entity = foundComponent.entity
            assetComponentSystem.removeComponent(foundComponent)
            assetEntities.removeAll { $0 === entity }

            if let regionNode = regionNode(at: assetInstance.placement.mapPosition) {
                regionNode.remove(assetInstance: assetInstance, includingPlacement: includingPlacement)
            }
        }
    }

    @discardableResult
    public final func addAsset(_ asset: AssetLocator, named: String, at position: MapPosition, horizontallyFlipped: Bool) throws -> AssetInstance? {
        if let regionNode = regionNode(at: position) {
            return try regionNode.addAsset(asset, named: "", atMapPosition: position, horizontallyFlipped: horizontallyFlipped)
        }
        return nil
    }

    public final func add(assetInstance: AssetInstance) throws {
        if let regionNode = regionNode(at: assetInstance.placement.mapPosition) {
            try regionNode.add(assetInstance: assetInstance)
        }
    }

    nonisolated public static func sceneToWorld(_ position: ScenePosition) -> WorldPosition {
        let xWorld = ((position.x / MapNode.halfTileSize.width) - (position.y / MapNode.halfTileSize.height)) / 2
        let yWorld = -(position.y / MapNode.halfTileSize.height) - xWorld
        return WorldPosition(Float(xWorld), Float(yWorld), 0)
    }

    nonisolated public static func worldToScene(_ position: WorldPosition) -> ScenePosition {
        let xScene = MapNode.halfTileSize.width * (position.x - position.y)
        let yScene = -MapNode.halfTileSize.height * (position.x + position.y) + position.z * Float(MapNode.elevationHeight)
        return ScenePosition(x: xScene, y: yScene)
    }

    nonisolated public static func sceneToMap(_ position: ScenePosition) -> MapPosition {
        let world = sceneToWorld(position)
        return world.mapPosition
    }

    nonisolated public static func mapToScene(_ position: MapPosition) -> ScenePosition {
        return worldToScene(position.worldPosition)
    }

}
