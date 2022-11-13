import SpriteKit
import GameplayKit

open class MapNode: SKNode, Collection {
    
    public static let elevationHeight: Int = 10
    
    public static let halfWidth: Int = 24
    public static let halfHeight: Int = 12
    
    public var regions: [MapRegion] = [MapRegion]()
    
    private let mapDescription: MapDescription
    
    public var ambientLight: BaseLight { mapDescription.lighting.ambientLight }
    
    public var lights: [PointLight] { mapDescription.lighting.lights }
    
    var layerCount:Int { 3 } // Temporary code
    
    public var startIndex: Int { regions.startIndex }
    public var endIndex: Int { regions.endIndex }
    
    public subscript(position: Int) -> MapRegion {
        return regions[position]
    }
    
    public init(description mapDescription: MapDescription) {
        self.mapDescription = mapDescription
        
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
    
    public func toMapDescription() -> MapDescription {
        var newMapDescription = MapDescription()
        for region in regions {
            newMapDescription.regions.append(region.regionDescription)
        }
        newMapDescription.lighting = mapDescription.lighting
        newMapDescription.renderers = mapDescription.renderers
        return newMapDescription
    }
    
    private func updateRegionsZPosition() {
        var index = 0
        for region in regions {
            region.zPosition = CGFloat(index)
            index += layerCount
        }
    }
    
    private func registerCellRenderers() {
        for (name, rendererDescription) in mapDescription.renderers {
            let renderer = CellRenderer(from: rendererDescription)
            try! CellRenderers.register(cellRenderer: renderer, named: name)
        }
    }
    
    public func sortRegions() {
        regions.sort()
        updateRegionsZPosition()
    }
    
    public func buildRegions() {
        for region in regions {
            region.build()
        }
        updateRegionsZPosition()
    }
    
    public func hasCell(forX x: Int, y: Int) -> Bool {
        for region in regions {
            if region.regionDescription.area.contains(x: x, y: y) {
                return true
            }
        }
        return false;
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
}
