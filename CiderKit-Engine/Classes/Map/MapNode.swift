import SpriteKit
import GameplayKit

open class MapNode: SKNode, Collection {
    
    public static let elevationHeight: Int = 10
    
    public static let tileWidth: Int = 48
    public static let tileHeight: Int = 24
    public static let tileSize = CGSize(width: CGFloat(MapNode.tileWidth), height: CGFloat(MapNode.tileHeight))

    public static let halfWidth: Int = MapNode.tileWidth / 2
    public static let halfHeight: Int = MapNode.tileHeight / 2
    public static let halfTileSize = CGSize(width: CGFloat(MapNode.halfWidth), height: CGFloat(MapNode.halfHeight))

    public static let xVector = SIMD2(Float(MapNode.halfWidth), Float(-MapNode.halfHeight))
    public static let yVector = SIMD2(Float(-MapNode.halfWidth), Float(-MapNode.halfHeight))
    public static let zVector = SIMD2(0, Float(MapNode.elevationHeight))

    public var regions: [MapRegion] = [MapRegion]()
    
    private let cellRenderers: [String:CellRendererDescription]
    
    public let ambientLight: BaseLight
    public var lights: [PointLight]
    
    public var startIndex: Int { regions.startIndex }
    public var endIndex: Int { regions.endIndex }
    
    public private(set) var assetEntities: [GKEntity] = []
    public let assetComponentSystem: GKComponentSystem<AssetComponent>
    
    public subscript(position: Int) -> MapRegion {
        return regions[position]
    }
    
    public init(description mapDescription: MapDescription) {
        cellRenderers = mapDescription.renderers
        
        ambientLight = mapDescription.lighting.ambientLight
        lights = mapDescription.lighting.lights
        
        assetComponentSystem = GKComponentSystem(componentClass: AssetComponent.self)
        
        super.init()
        
        registerCellRenderers()
        
        for regionDescription in mapDescription.regions {
            let region = MapRegion(forMap: self, description: regionDescription)
            regions.append(region)
            addChild(region)
        }
        
        sortRegions()
        buildRegions()
        
        zPosition = 2
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func index(after i: Int) -> Int { regions.index(after: i) }
    
    public func regionAt(mapX x: Int, y: Int) -> MapRegion? { regions.first(where: { $0.containsMapCoordinates(mapX: x, y: y) }) }

    public func regionAt(mapPosition position: MapPosition) -> MapRegion? { regionAt(mapX: position.x, y: position.y) }

    public func hasCell(forMapX x: Int, y: Int) -> Bool { regionAt(mapX: x, y: y) != nil }

    public func toMapDescription() -> MapDescription {
        var newMapDescription = MapDescription()
        for region in regions {
            newMapDescription.regions.append(region.regionDescription)
        }
        
        newMapDescription.renderers = cellRenderers
        
        var lighting = LightingDescription(ambientLight: ambientLight)
        lighting.lights = lights
        newMapDescription.lighting = lighting
        
        return newMapDescription
    }
    
    private func updateRegionsZPosition() {
        var index = 0
        for region in regions {
            region.zPosition = CGFloat(index)
            index += region.layerCount
        }
    }
    
    private func registerCellRenderers() {
        for (name, rendererDescription) in cellRenderers {
            let renderer = CellRenderer(from: rendererDescription)
            try! CellRenderers.register(cellRenderer: renderer, named: name)
        }
    }
    
    public func sortRegions() {
        regions.sort()
    }
    
    open func buildRegions() {
        for region in regions {
            region.build()
        }
        updateRegionsZPosition()
    }
    
    func getLeftVisibleElevation(forX x: Int, y: Int, usingDefaultElevation defaultElevation: Int) -> Int {
        guard
            let cellElevation = getCellElevation(forX: x, y: y),
            let leftCellElevation = getCellElevation(forX: x, y: y + 1)
        else {
            return defaultElevation
        }
        
        let diff = cellElevation - leftCellElevation
        return Swift.max(diff, 0)
    }
    
    func getRightVisibleElevation(forX x: Int, y: Int, usingDefaultElevation defaultElevation: Int) -> Int {
        guard
            let cellElevation = getCellElevation(forX: x, y: y),
            let rightCellElevation = getCellElevation(forX: x + 1, y: y)
        else {
            return defaultElevation
        }
        
        let diff = cellElevation - rightCellElevation
        return Swift.max(diff, 0)
    }
    
    func getCellElevation(forX x: Int, y: Int) -> Int? {
        for region in regions {
            if region.containsMapCoordinates(mapX: x, y: y) {
                return region.regionDescription.elevation
            }
        }
        return nil
    }
    
    public func lookForMapCellEntity(atMapPosition position: MapPosition) -> GKEntity? {
        for region in regions {
            for cell in region.cellEntities {
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
        for region in regions {
            for cell in region.cellEntities {
                if let cellComponent = cell.component(ofType: MapCellComponent.self), cellComponent.contains(sceneCoordinates: sceneCoordinates){
                    return cellComponent
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

    open func mapCellEntity(node: SKNode, for region: MapRegion, atMapPosition position: MapPosition) -> GKEntity {
        let entity = GKEntity()
        entity.addComponent(GKSKNodeComponent(node: node))
        let cell = mapCellComponent(for: region, atMapPosition: position)
        entity.addComponent(cell)
        return entity
    }
    
    open func mapCellComponent(for region: MapRegion, atMapPosition position: MapPosition) -> MapCellComponent {
        return MapCellComponent(region: region, position: position)
    }
    
    public func getAssetPlacement(by id: UUID) -> AssetPlacement? {
        for region in regions {
            if let placement = region.regionDescription.assetPlacements?.first(where: { $0.id == id }) {
                return placement
            }
        }
        return nil
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

    open func remove(assetInstance: AssetInstance) {
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
        }
    }

    @discardableResult
    public final func addAsset(_ asset: AssetLocator, named: String, atMapPosition: MapPosition, horizontallyFlipped: Bool) throws -> AssetInstance? {
        if let region = regionAt(mapPosition: atMapPosition) {
            return try region.addAsset(asset, named: "", atMapPosition: atMapPosition, horizontallyFlipped: horizontallyFlipped)
        }
        return nil
    }

    public final func add(assetInstance: AssetInstance) throws {
        if let region = regionAt(mapPosition: assetInstance.placement.mapPosition) {
            try region.addAssetInstance(assetInstance)
        }
    }

    public static func sceneToWorld(_ position: ScenePosition) -> WorldPosition {
        let xWorld = ((position.x / MapNode.halfTileSize.width) - (position.y / MapNode.halfTileSize.height)) / 2
        let yWorld = -(position.y / MapNode.halfTileSize.height) - xWorld
        return WorldPosition(Float(xWorld), Float(yWorld), 0)
    }

    public static func worldToScene(_ position: WorldPosition) -> ScenePosition {
        let xScene = MapNode.halfTileSize.width * (position.x - position.y)
        let yScene = -MapNode.halfTileSize.height * (position.x + position.y) + position.z * Float(MapNode.elevationHeight)
        return ScenePosition(x: xScene, y: yScene)
    }

    public static func sceneToMap(_ position: ScenePosition) -> MapPosition {
        let world = sceneToWorld(position)
        return world.mapPosition
    }

    public static func mapToScene(_ position: MapPosition) -> ScenePosition {
        return worldToScene(position.worldPosition)
    }

}
