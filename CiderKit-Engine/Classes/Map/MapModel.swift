import Combine
import CoreGraphics

@globalActor
public actor MapModel: GlobalActor {

    public static let shared = MapModel()

    @MainActor
    public private(set) var currentMapDescription: MapDescription = MapDescription()

    @MainActor
    public private(set) var currentMapVersion: UInt64 = 0

    internal var cellRenderers: [String: CellRendererDescription]

    public var ambientLight: AmbientLight
    public var lights: [any LightImplementation]

    private var workingMapDescription: MapDescription

    private init() {
        workingMapDescription = MapDescription()

        cellRenderers = [:]
        ambientLight = AmbientLight()
        lights = []
    }

    public func match(mapDescription: MapDescription) async {
        workingMapDescription = mapDescription

        cellRenderers = workingMapDescription.renderers

        ambientLight.match(description: workingMapDescription.lighting.ambientLight)
        lights = workingMapDescription.lighting.lights.map { $0.toImplementation() }

        await pushNewMapVersion(mapDescription)
    }

    public func clear() async {
        workingMapDescription = MapDescription()
        await pushNewMapVersion(workingMapDescription)
    }

    public func regionAt(mapX x: Int, y: Int) -> MapRegionDescription? {
        workingMapDescription.regions.first(where: { $0.area.contains(mapX: x, y: y) })
    }

    public func regionAt(mapPosition position: MapPosition) -> MapRegionDescription? { regionAt(mapX: position.x, y: position.y) }

    public func rename(regionId: Int, to newName: String) async {
        await pushNewMapVersion(workingMapDescription.mutated(withRegions: workingMapDescription.regions.map { regionDescription in
            guard regionDescription.id == regionId else { return regionDescription }
            return regionDescription.mutated(withName: newName)
        }))
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

        for i in 0..<workingMapDescription.regions.count {
            let regionDescription = workingMapDescription.regions[i]
            if area == nil || area!.contains(absolute: regionDescription.area) {
                appliedOnRegion = true
                if let newRegionDescription = changeFunc(regionDescription) {
                    mapDescription.regions[i] = newRegionDescription
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
                    mapDescription.regions[i] = newRegionDescription
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
    
    fileprivate static func merge(regions: inout [MapRegionDescription]) -> Bool {
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
        for region in workingMapDescription.regions {
            if let placement = region.assetPlacements.first(where: { $0.id == id }) {
                return placement
            }
        }
        return nil
    }

    @discardableResult
    public func addAsset(_ asset: AssetLocator, named name: String, atMapPosition mapPosition: MapPosition, horizontallyFlipped: Bool) async throws -> AssetPlacementDescription? {
        var footprint = asset.assetDescription!.footprint
        if horizontallyFlipped {
            footprint.flip()
        }

        var regions = workingMapDescription.regions

        for i in 0..<regions.count {
            let region = regions[i]
            
            if try region.isLocationValidAndFreeOfAssets(mapPosition: mapPosition, footprint: footprint) {
                let placement = AssetPlacementDescription(id: UUID(), assetLocator: asset, horizontallyFlipped: horizontallyFlipped, position: mapPosition, name: name)
                regions[i] = region.withAssetPlacement(added: placement)
                await pushNewMapVersion(workingMapDescription.mutated(withRegions: regions))
                return placement
            }
        }
        
        return nil
    }
    
    public func update(assetPlacement: AssetPlacementDescription) async {
        await pushNewMapVersion(workingMapDescription.mutated(withRegions: workingMapDescription.regions.map {
            $0.withAssetPlacement(updated: assetPlacement)
        }))
    }
    
    @discardableResult
    public func removeAsset(withId placementId: UUID) async -> Bool {
        var regions = workingMapDescription.regions
        for i in 0..<regions.count {
            if let newRegion = regions[i].withAssetPlacement(removed: placementId) {
                regions[i] = newRegion
                await pushNewMapVersion(workingMapDescription.mutated(withRegions: regions))
                return true
            }
        }
        return false
    }

    private func pushNewMapVersion(_ newMapDescription: MapDescription) async {
        workingMapDescription = newMapDescription
        await MainActor.run {
            self.currentMapDescription = newMapDescription
            self.currentMapVersion += 1
        }
    }

}
