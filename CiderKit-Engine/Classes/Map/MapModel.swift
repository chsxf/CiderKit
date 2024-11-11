import Combine

open class MapModel {

    public var regions = [MapRegionModel]()

    internal let cellRenderers: [String:CellRendererDescription]

    public let ambientLight: BaseLight
    public var lights: [PointLight]

    public let changed = PassthroughSubject<MapModel, Never>()
    
    public init(with description: MapDescription) {
        cellRenderers = description.renderers

        ambientLight = description.lighting.ambientLight
        lights = description.lighting.lights

        description.regions.forEach {
            let regionModel = MapRegionModel(with: $0, in: self)
            regions.append(regionModel)
        }

        sortRegions()
    }

    public func sortRegions() {
        regions.sort(by: <)
    }

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

    public func regionAt(mapX x: Int, y: Int) -> MapRegionModel? { regions.first(where: { $0.containsMapCoordinates(mapX: x, y: y) }) }

    public func regionAt(mapPosition position: MapPosition) -> MapRegionModel? { regionAt(mapX: position.x, y: position.y) }

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
        regionAt(mapX: x, y: y)?.regionDescription.elevation
    }

    public func add(light: PointLight) {
        lights.append(light)
        changed.send(self)
    }

    @discardableResult
    public func remove(light: PointLight) -> Bool {
        let countBefore = lights.count
        lights.removeAll { $0 === light }
        if countBefore != lights.count {
            changed.send(self)
            return true
        }
        return false
    }
    
    fileprivate func changeElevation(area: MapArea?, createIfNotApplied: Bool, changeFunc: (MapRegionModel) -> Bool) {
        var appliedOnRegion = false
        var needsRebuilding = false

        var regionsToRemove = [MapRegionModel]()
        var newRegions = [MapRegionModel]()

        for regionModel in regions {
            if area == nil || area!.contains(absolute: regionModel.regionDescription.area) {
                appliedOnRegion = true
                if changeFunc(regionModel) {
                    needsRebuilding = true
                }
                break
            }
            else if area != nil {
                guard let subdivisions = regionModel.subdivide(subArea: area!) else {
                    continue
                }
                
                appliedOnRegion = true
                regionsToRemove.append(regionModel)
                for subdivision in subdivisions.otherSubdivisions {
                    newRegions.append(subdivision)
                }
                newRegions.append(subdivisions.mainSubdivision)
                let _ = changeFunc(subdivisions.mainSubdivision)
                needsRebuilding = true
                break
            }
        }
        
        if !appliedOnRegion && createIfNotApplied {
            let newDescription = MapRegionDescription(area: area!, elevation: 1, renderer: nil)
            let newRegionModel = MapRegionModel(with: newDescription, in: self)
            newRegions.append(newRegionModel)
            needsRebuilding = true
        }

        let hasRegionsToRemove = !regionsToRemove.isEmpty
        let hasNewRegions = !newRegions.isEmpty
        if hasRegionsToRemove || hasNewRegions {
            if hasRegionsToRemove {
                regions.removeAll { regionsToRemove.contains($0) }
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
            changed.send(self)
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
                let regionModel = regions[i]
                for i2 in i+1..<regions.count {
                    let regionModel2 = regions[i2]
                    if let newRegionDescription = regionModel.regionDescription.merged(with: regionModel2.regionDescription) {
                        let newRegionModel = MapRegionModel(with: newRegionDescription, in: self)
                        regions[i] = newRegionModel
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
        changeElevation(area: area, createIfNotApplied: true) { $0.increaseElevation() }
    }
    
    public func decreaseElevation(area: MapArea?) {
        changeElevation(area: area, createIfNotApplied: false) { $0.decreaseElevation() }
    }

    public func getAssetPlacement(by id: UUID) -> AssetPlacement? {
        for region in regions {
            if let placement = region.regionDescription.assetPlacements.first(where: { $0.id == id }) {
                return placement
            }
        }
        return nil
    }

    @discardableResult
    public func removeAsset(with placementId: UUID) -> Bool {
        for region in regions {
            if region.removeAssetPlacement(with: placementId) {
                changed.send(self)
                return true
            }
        }
        return false
    }

}
