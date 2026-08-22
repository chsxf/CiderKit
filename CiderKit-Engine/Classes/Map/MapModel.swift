import Combine
import CoreGraphics

@globalActor
public actor MapModel: GlobalActor {

    public static let shared = MapModel()

    public private(set) var regions = [MapRegionDescription]()

    internal var cellRenderers: [String: CellRendererDescription]

    public var ambientLight: AmbientLight
    public var lights: [any LightImplementation]

    private init() {
        cellRenderers = [:]
        ambientLight = AmbientLight()
        lights = []
    }

    public func match(mapDescription: MapDescription) {
        cellRenderers = mapDescription.renderers

        ambientLight.match(description: mapDescription.lighting.ambientLight)
        lights = mapDescription.lighting.lights.map { $0.toImplementation() }
        
        regions = mapDescription.regions
        sortRegions()
    }

    public func clear() {
        cellRenderers.removeAll()
        ambientLight.reset()
        lights.removeAll()
        regions.removeAll()
    }

    public func sortRegions() {
        regions.sort(by: <)
    }

    public func toMapDescription() -> MapDescription {
        MapDescription(
            regions: regions,
            lighting: LightingDescription(ambientLight: ambientLight.description, lights: lights.map { $0.description }),
            renderers: cellRenderers
        )
    }

    public func regionAt(mapX x: Int, y: Int) -> MapRegionDescription? { regions.first(where: { $0.area.contains(mapX: x, y: y) }) }

    public func regionAt(mapPosition position: MapPosition) -> MapRegionDescription? { regionAt(mapX: position.x, y: position.y) }

    public func rename(regionId: Int, to newName: String) {
        regions = regions.map { regionDescription in
            guard regionDescription.id == regionId else { return regionDescription }
            return regionDescription.mutated(withName: newName)
        }
    }
    
    public func hasCell(forMapX x: Int, y: Int) -> Bool { regionAt(mapX: x, y: y) != nil }

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
        regionAt(mapX: x, y: y)?.elevation
    }

    public func add(light: any LightImplementation) {
        lights.append(light)
    }

    @discardableResult
    public func remove(light: any LightImplementation) -> Bool {
        let countBefore = lights.count
        lights.removeAll { $0 === light }
        if countBefore != lights.count {
            return true
        }
        return false
    }
    
    fileprivate func changeElevation(area: MapArea?, createIfNotApplied: Bool, changeFunc: (MapRegionDescription) -> MapRegionDescription?) {
        var appliedOnRegion = false
        var needsRebuilding = false

        var regionsToRemove = [MapRegionDescription]()
        var newRegions = [MapRegionDescription]()

        for i in 0..<regions.count {
            let regionDescription = regions[i]
            if area == nil || area!.contains(absolute: regionDescription.area) {
                appliedOnRegion = true
                if let newRegionDescription = changeFunc(regionDescription) {
                    regions[i] = newRegionDescription
                    needsRebuilding = true
                }
                break
            }
            else if area != nil {
                guard let subdivisions = regionDescription.subdivide(subArea: area!) else {
                    continue
                }
                
                appliedOnRegion = true
                regionsToRemove.append(regionDescription)
                for subdivision in subdivisions.otherSubdivisions {
                    newRegions.append(subdivision)
                }
                newRegions.append(subdivisions.mainSubdivision)
                if let newRegionDescription = changeFunc(subdivisions.mainSubdivision) {
                    regions[i] = newRegionDescription
                }
                needsRebuilding = true
                break
            }
        }
        
        if let area, !appliedOnRegion, createIfNotApplied {
            let newDescription = MapRegionDescription(area: area, elevation: 1, renderer: nil)
            newRegions.append(newDescription)
            needsRebuilding = true
        }

        let hasRegionsToRemove = !regionsToRemove.isEmpty
        let hasNewRegions = !newRegions.isEmpty
        if hasRegionsToRemove || hasNewRegions {
            if hasRegionsToRemove {
                regions.removeAll { outerRegionDescription in
                    regionsToRemove.contains { innerRegionDescription in
                        outerRegionDescription.id == innerRegionDescription.id
                    }
                }
            }
            if hasNewRegions {
                regions.append(contentsOf: newRegions)
            }
            if mergeRegions() {
                needsRebuilding = true
            }
        }

        if needsRebuilding {
            sortRegions()
        }
    }
    
    fileprivate func mergeRegions() -> Bool {
        guard regions.count > 1 else {
            return false
        }
        
        var result = false
        
        var regionsHaveChanged: Bool
        repeat {
            regionsHaveChanged = false
            var i = 0
            while i < regions.count-1 {
                let region1 = regions[i]
                for i2 in i+1..<regions.count {
                    let region2 = regions[i2]
                    if let newRegionDescription = region1.merged(with: region2) {
                        regions[i] = newRegionDescription
                        regions.remove(at: i2)
                        regionsHaveChanged = true
                        result = true
                        break
                    }
                }
                i += 1
            }
        } while regionsHaveChanged
        
        return result
    }
    
    public func increaseElevation(area: MapArea?) {
        changeElevation(area: area, createIfNotApplied: true) { $0.elevated(by: 1) }
    }
    
    public func decreaseElevation(area: MapArea?) {
        changeElevation(area: area, createIfNotApplied: false) { $0.elevated(by: -1) }
    }

    public func getAssetPlacement(withId id: UUID) -> AssetPlacementDescription? {
        for region in regions {
            if let placement = region.assetPlacements.first(where: { $0.id == id }) {
                return placement
            }
        }
        return nil
    }

    @discardableResult
    public func addAsset(_ asset: AssetLocator, named name: String, atMapPosition mapPosition: MapPosition, horizontallyFlipped: Bool) throws -> AssetPlacementDescription? {
        var footprint = asset.assetDescription!.footprint
        if horizontallyFlipped {
            footprint.flip()
        }
        
        for i in 0..<regions.count {
            let region = regions[i]
            
            if try region.isLocationValidAndFreeOfAssets(mapPosition: mapPosition, footprint: footprint) {
                let placement = AssetPlacementDescription(id: UUID(), assetLocator: asset, horizontallyFlipped: horizontallyFlipped, position: mapPosition, name: name)
                regions[i] = region.withAssetPlacement(added: placement)
                return placement
            }
        }
        
        return nil
    }
    
    public func update(assetPlacement: AssetPlacementDescription) {
        regions = regions.map { $0.withAssetPlacement(updated: assetPlacement) }
    }
    
    @discardableResult
    public func removeAsset(withId placementId: UUID) -> Bool {
        for i in 0..<regions.count {
            if let newRegion = regions[i].withAssetPlacement(removed: placementId) {
                regions[i] = newRegion
                return true
            }
        }
        return false
    }

}
