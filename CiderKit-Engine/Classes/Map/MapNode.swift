import SpriteKit
import GameplayKit

open class MapNode: SKNode, Collection, ObservableObject {
    
    static let elevationHeight: Int = 10
    
    static let halfWidth: Int = 24
    static let halfHeight: Int = 12
    
    public var regions: [MapRegion] = [MapRegion]()
    
    private let mapDescription: MapDescription
    
    var layerCount:Int { 3 } // Temporary code
    
    public var startIndex: Int { regions.startIndex }
    public var endIndex: Int { regions.endIndex }
    
    public subscript(position: Int) -> MapRegion {
        return regions[position]
    }
    
    public override required init() {
        fatalError("init() has not been implemented")
    }
    
    public init(description mapDescription: MapDescription) {
        self.mapDescription = mapDescription
        
        super.init()
        
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
        var mapDescription = MapDescription()
        for region in regions {
            mapDescription.regions.append(region.regionDescription)
        }
        return mapDescription
    }
    
    private func updateRegionsZPosition() {
        var index = 0
        for region in regions {
            region.zPosition = CGFloat(index)
            index += layerCount
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
    
    func getLeftVisibleElevation(forX x: Int, andY y: Int, usingDefaultElevation defaultElevation: Int) -> Int {
        guard
            let cellElevation = getCellElevation(forX: x, andY: y),
            let leftCellElevation = getCellElevation(forX: x, andY: y + 1)
        else {
            return defaultElevation
        }
        
        let diff = cellElevation - leftCellElevation
        return Swift.max(diff, 0)
    }
    
    func getRightVisibleElevation(forX x: Int, andY y: Int, usingDefaultElevation defaultElevation: Int) -> Int {
        guard
            let cellElevation = getCellElevation(forX: x, andY: y),
            let rightCellElevation = getCellElevation(forX: x + 1, andY: y)
        else {
            return defaultElevation
        }
        
        let diff = cellElevation - rightCellElevation
        return Swift.max(diff, 0)
    }
    
    func getCellElevation(forX x: Int, andY y: Int) -> Int? {
        for region in regions {
            if region.containsMapCoordinates(x: x, y: y) {
                return region.regionDescription.elevation
            }
        }
        return nil
    }
    
    func getWorldPosition(atCellX x: Int, y: Int) -> CGPoint? {
        guard let elevation = getCellElevation(forX: x, andY: y) else {
            return nil
        }
        
        let isoX = MapNode.halfWidth * (x + y + 1)
        let isoY = MapNode.halfHeight * (y - x + 1) + (elevation * MapNode.elevationHeight)
        
        return CGPoint(x: isoX, y: isoY)
    }
    
    public func getMapCellEntity(atX x: Int, y: Int) -> GKEntity? {
        for region in regions {
            for cell in region.cellEntities {
                guard let cellComponent = cell.component(ofType: MapCellComponent.self) else {
                    continue
                }
                if cellComponent.mapX == x && cellComponent.mapY == y {
                    return cell
                }
            }
        }
        return nil
    }
    
}
