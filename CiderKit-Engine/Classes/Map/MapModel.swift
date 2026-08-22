import Combine
import CoreGraphics

private typealias MapDescriptionStream = (stream: AsyncStream<MapDescription>, continuation: AsyncStream<MapDescription>.Continuation)

@globalActor
public actor MapModel: GlobalActor {

    public static let shared = MapModel()

    internal var cellRenderers: [String: CellRendererDescription]

    public var ambientLight: AmbientLight
    public var lights: [any LightImplementation]

    private var workingMapDescription: MapDescription

    private var updateStreams = [MapDescriptionStream]()
    public var updateStream: AsyncStream<MapDescription> { makeUpdateStream() }

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

    public func renameRegion(by id: Int, to newName: String) async {
        await pushNewMapVersion(workingMapDescription.mutated(withRegions: workingMapDescription.regions.map { regionDescription in
            guard regionDescription.id == id else { return regionDescription }
            return regionDescription.mutated(withName: newName)
        }))
    }

    public func add(light: any LightDescriptor) async {
        let lightingVersionBefore = workingMapDescription.lighting.version
        let newLightingDescription = workingMapDescription.lighting.add(light: light)
        if lightingVersionBefore != newLightingDescription.version {
            let newMapDescription = workingMapDescription.mutated(withLighting: newLightingDescription)
            await pushNewMapVersion(newMapDescription)
        }
    }

    @discardableResult
    public func remove(light: any LightDescriptor) async -> Bool {
        let lightingVersionBefore = workingMapDescription.lighting.version
        let newLightingDescription = workingMapDescription.lighting.removeLight(by: light.id)
        if lightingVersionBefore != newLightingDescription.version {
            let newMapDescription = workingMapDescription.mutated(withLighting: newLightingDescription)
            await pushNewMapVersion(newMapDescription)
            return true
        }
        return false
    }
    
    fileprivate func changeElevation(area: MapArea?, createIfNotApplied: Bool, changeFunc: (MapRegionDescription) -> MapRegionDescription?) async {
        var hasChanged = false
        var appliedOnRegion = false
        var needsSorting = false

        var modifiedRegions = workingMapDescription.regions

        var regionsToRemove = [MapRegionDescription]()
        var newRegions = [MapRegionDescription]()

        for i in 0..<modifiedRegions.count {
            let regionDescription = modifiedRegions[i]
            if area == nil || area!.contains(absolute: regionDescription.area) {
                appliedOnRegion = true
                if let newRegionDescription = changeFunc(regionDescription) {
                    modifiedRegions[i] = newRegionDescription
                    hasChanged = true
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
                    modifiedRegions[i] = newRegionDescription
                }
                hasChanged = true
                needsSorting = true
                break
            }
        }
        
        if let area, !appliedOnRegion, createIfNotApplied {
            let newDescription = MapRegionDescription(area: area, elevation: 1, renderer: nil)
            newRegions.append(newDescription)
            hasChanged = true
            needsSorting = true
        }

        let hasRegionsToRemove = !regionsToRemove.isEmpty
        let hasNewRegions = !newRegions.isEmpty
        if hasRegionsToRemove || hasNewRegions {
            if hasRegionsToRemove {
                modifiedRegions.removeAll { outerRegionDescription in
                    regionsToRemove.contains { innerRegionDescription in
                        outerRegionDescription.id == innerRegionDescription.id
                    }
                }
            }
            if hasNewRegions {
                modifiedRegions.append(contentsOf: newRegions)
            }
            if Self.merge(regions: &modifiedRegions) {
                needsSorting = true
            }
        }

        if needsSorting {
            modifiedRegions.sort(by: <)
        }

        if hasChanged {
            await pushNewMapVersion(workingMapDescription.mutated(withRegions: modifiedRegions))
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
    
    public func increaseElevation(area: MapArea?) async {
        await changeElevation(area: area, createIfNotApplied: true) { $0.elevated(by: 1) }
    }
    
    public func decreaseElevation(area: MapArea?) async {
        await changeElevation(area: area, createIfNotApplied: false) { $0.elevated(by: -1) }
    }

    @discardableResult
    public func addAsset(_ asset: AssetLocator, named name: String, atMapPosition mapPosition: MapPosition, horizontallyFlipped: Bool, interactive: Bool) async throws -> AssetPlacementDescription? {
        var footprint = asset.assetDescription!.footprint
        if horizontallyFlipped {
            footprint.flip()
        }

        var regions = workingMapDescription.regions

        for i in 0..<regions.count {
            let region = regions[i]
            do {
                try region.checkLocationOccupancy(mapPosition: mapPosition, footprint: footprint)

                let placement = AssetPlacementDescription(id: UUID(), assetLocator: asset, name: name, mapPosition: mapPosition, horizontallyFlipped: horizontallyFlipped, interactive: interactive)
                regions[i] = region.withAssetPlacement(added: placement)
                await pushNewMapVersion(workingMapDescription.mutated(withRegions: regions))
                return placement
            }
            catch MapRegionErrors.assetOutside { }
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
        updateStreams.forEach { $0.continuation.yield(newMapDescription) }
    }

    private func makeUpdateStream() -> AsyncStream<MapDescription> {
        let streamData = AsyncStream<MapDescription>.makeStream(bufferingPolicy: .bufferingNewest(0))
        updateStreams.append(streamData)
        return streamData.stream
    }

}
