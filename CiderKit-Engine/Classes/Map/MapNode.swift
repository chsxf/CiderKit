import SpriteKit
import GameplayKit

open class MapNode: SKNode, Collection {
    
    public static let elevationHeight: Int = 10
    
    public static let halfWidth: Int = 24
    public static let halfHeight: Int = 12
    
    public static let xVector = vector_float2(Float(MapNode.halfWidth), Float(-MapNode.halfHeight))
    public static let yVector = vector_float2(Float(-MapNode.halfWidth), Float(-MapNode.halfHeight))
    public static let zVector = vector_float2(0, Float(MapNode.elevationHeight))
    
    public var regions: [MapRegion] = [MapRegion]()
    
    private let cellRenderers: [String:CellRendererDescription]
    
    public let ambientLight: BaseLight
    public var lights: [PointLight]
    
    public var startIndex: Int { regions.startIndex }
    public var endIndex: Int { regions.endIndex }
    
    public subscript(position: Int) -> MapRegion {
        return regions[position]
    }
    
    public init(description mapDescription: MapDescription) {
        cellRenderers = mapDescription.renderers
        
        ambientLight = mapDescription.lighting.ambientLight
        lights = mapDescription.lighting.lights
        
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
    
    public func regionAt(x: Int, y: Int) -> MapRegion? {
        regions.first(where: { $0.containsMapCoordinates(x: x, y: y) })
    }
    
    public func hasCell(forX x: Int, y: Int) -> Bool { regionAt(x: x, y: y) != nil }
    
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
            if region.containsMapCoordinates(x: x, y: y) {
                return region.regionDescription.elevation
            }
        }
        return nil
    }
    
    func getWorldPosition(atCellX x: Int, y: Int) -> CGPoint? {
        guard let elevation = getCellElevation(forX: x, y: y) else {
            return nil
        }
        
        let isoX = MapNode.halfWidth * (x + y + 1)
        let isoY = MapNode.halfHeight * (y - x + 1) + (elevation * MapNode.elevationHeight)
        
        return CGPoint(x: isoX, y: isoY)
    }
    
    public func lookForMapCellEntity(atX x: Int, y: Int) -> GKEntity? {
        for region in regions {
            for cell in region.cellEntities {
                for component in cell.components {
                    if let cellComponent = component as? MapCellComponent {
                        if cellComponent.mapX == x && cellComponent.mapY == y {
                            return cell
                        }
                        break
                    }
                }
            }
        }
        return nil
    }
    
    open func mapCellEntity(node: SKNode, for region: MapRegion, atX x: Int, y: Int, elevation: Int) -> GKEntity {
        let entity = GKEntity()
        entity.addComponent(GKSKNodeComponent(node: node))
        let cell = mapCellComponent(for: region, atX: x, y: y, elevation: elevation)
        entity.addComponent(cell)
        return entity
    }
    
    open func mapCellComponent(for region: MapRegion, atX x: Int, y: Int, elevation: Int) -> MapCellComponent {
        return MapCellComponent(region: region, mapX: x, mapY: y, elevation: elevation)
    }
    
    public func getAssetPlacement(by id: UUID) -> AssetPlacement? {
        for region in regions {
            if let placement = region.regionDescription.assets?.first(where: { $0.id == id }) {
                return placement
            }
        }
        return nil
    }
    
    open func instantiateAsset(placement: AssetPlacement, at worldPosition: SIMD3<Float>) -> AssetInstance? {
        AssetInstance(placement: placement, at: worldPosition)
    }
    
    public static func computeNodePosition(with offset: SIMD3<Float>) -> CGPoint { computeNodePosition(x: offset.x, y: offset.y, z: offset.z) }
    
    public static func computeNodePosition(x: Float, y: Float, z: Float) -> CGPoint {
        let v2 = (Self.xVector * x) + (Self.yVector * y) + (Self.zVector * z)
        return CGPoint(x: CGFloat(v2.x), y: CGFloat(v2.y))
    }
    
}
