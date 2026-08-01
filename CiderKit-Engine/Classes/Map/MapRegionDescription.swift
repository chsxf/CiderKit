import Foundation

public struct MapRegionDescription: Codable, Sendable {
    
    private enum MaterialOverrideContext: String {
        case ground = "g"
        case leftElevation = "l"
        case rightElevation = "r"
    }

    public let name: String?

    public let materialOverrides: [String: [CustomSettings?]]?
    
    public let elevation: Int
    public let renderer: String?
    
    public let assetPlacements: [AssetPlacementDescription]
    
    public let area: MapArea
    
    public init(area: MapArea, elevation: Int, renderer: String?) {
        self.init(name: nil, area: area, elevation: elevation, renderer: renderer, materialOverrides: nil, assetPlacements: [])
    }
    
    internal init(byExporting area: MapArea, from other: MapRegionDescription) {
        var materialOverrides: [String: [CustomSettings?]]? = nil
        Self.importMaterialOverrides(over: area, from: other, into: &materialOverrides)
        var assetPlacements = [AssetPlacementDescription]()
        Self.importAssets(over: area, from: other, into: &assetPlacements)
        
        self.init(name: nil, area: area, elevation: other.elevation, renderer: other.renderer, materialOverrides: materialOverrides, assetPlacements: assetPlacements)
    }
    
    private init(name: String?, area: MapArea, elevation: Int, renderer: String?, materialOverrides: [String: [CustomSettings?]]?, assetPlacements: [AssetPlacementDescription]) {
        self.name = name
        self.area = area
        self.elevation = elevation
        
        self.renderer = renderer
        self.materialOverrides = materialOverrides
        
        self.assetPlacements = assetPlacements
    }
    
    public func isFreeOfAsset(mapArea: MapArea) -> Bool {
        for placement in assetPlacements {
            if let description = placement.assetLocator.assetDescription {
                var footprint = description.footprint
                if placement.horizontallyFlipped {
                    footprint.flip()
                }

                let assetArea = MapArea(x: placement.mapPosition.x - Int(footprint.x), y: placement.mapPosition.y - Int(footprint.y), width: Int(footprint.x), height: Int(footprint.y))
                if assetArea.intersects(mapArea) {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func getMaterialOverride(for context: MaterialOverrideContext, at index: Int) -> CustomSettings? {
        guard
            let container = materialOverrides?[context.rawValue],
            index >= 0,
            index < container.count
        else {
            return nil
        }
        return container[index]
    }
    
    func groundMaterialOverride(at index: Int) -> CustomSettings? {
        return getMaterialOverride(for: MaterialOverrideContext.ground, at: index)
    }
    
    func leftElevationMaterialOverride(at index: Int) -> CustomSettings? {
        return getMaterialOverride(for: MaterialOverrideContext.leftElevation, at: index)
    }
    
    func rightElevationMaterialOverride(at index: Int) -> CustomSettings? {
        return getMaterialOverride(for: MaterialOverrideContext.rightElevation, at: index)
    }
    
    public func merged(with other: MapRegionDescription) -> MapRegionDescription? {
        guard elevation == other.elevation, renderer == other.renderer else {
            return nil
        }
        
        var newArea: MapArea? = nil
        
        if area.width == other.area.width && area.minX == other.area.minX
                    && (area.maxY == other.area.minY || other.area.maxY == area.minY) {
            newArea = MapArea(x: area.minX, y: min(area.minY, other.area.minY), width: area.width, height: area.height + other.area.height)
        }
        else if area.height == other.area.height && area.minY == other.area.minY
                    && (area.maxX == other.area.minX || other.area.maxX == area.minX) {
            newArea = MapArea(x: min(area.minX, other.area.minX), y: area.minY, width: area.width + other.area.width, height: area.height)
        }

        guard let unwrappedNewArea = newArea else { return nil }

        var materialOverrides: [String: [CustomSettings?]]? = nil
        Self.importMaterialOverrides(over: unwrappedNewArea, from: self, into: &materialOverrides)
        Self.importMaterialOverrides(over: unwrappedNewArea, from: other, into: &materialOverrides)
        
        var assetPlacemeents = [AssetPlacementDescription]()
        Self.importAssets(over: unwrappedNewArea, from: self, into: &assetPlacemeents)
        Self.importAssets(over: unwrappedNewArea, from: other, into: &assetPlacemeents)
        
        return MapRegionDescription(name: nil, area: unwrappedNewArea, elevation: elevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: [])
    }
    
    public func renamed(as newName: String) -> MapRegionDescription {
        MapRegionDescription(name: newName, area: area, elevation: elevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: assetPlacements)
    }
    
    public func elevated(by relativeElevation: Int) -> MapRegionDescription {
        guard relativeElevation != 0 else { return self }
        let newAssetPlacements = changeAssetPlacementsElevation(placements: assetPlacements, relativeElevation: relativeElevation)
        let newElevation = elevation + relativeElevation
        return MapRegionDescription(name: name, area: area, elevation: newElevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: newAssetPlacements)
    }
    
    public func withAssetPlacement(added newAssetPlacement: AssetPlacementDescription) -> MapRegionDescription {
        var newAssetPlacements = assetPlacements;
        newAssetPlacements.append(newAssetPlacement)
        return MapRegionDescription(name: name, area: area, elevation: elevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: newAssetPlacements)
    }
    
    public func withAssetPlacement(updated updatedAssetPlacement: AssetPlacementDescription) -> MapRegionDescription {
        for i in 0..<assetPlacements.count {
            let placement = assetPlacements[i]
            if placement.id == updatedAssetPlacement.id {
                var newAssetPlacements = assetPlacements
                newAssetPlacements[i] = updatedAssetPlacement
                return MapRegionDescription(name: name, area: area, elevation: elevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: newAssetPlacements)
            }
        }
        return self
    }
    
    public func withAssetPlacement(removed assetPlacementId: UUID) -> MapRegionDescription? {
        let newAssetPlacements = assetPlacements.compactMap { $0.id != assetPlacementId ? $0 : nil }
        if newAssetPlacements.count != assetPlacements.count {
            return MapRegionDescription(name: name, area: area, elevation: elevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: newAssetPlacements)
        }
        return nil
    }
    
    private static func importMaterialOverrides(over area: MapArea, from region: MapRegionDescription, into existingMaterialOverrides: inout [String: [CustomSettings?]]?) {
        let relativeArea = region.area.relative(to: area)
        importMaterialOverrides(over: area, for: MaterialOverrideContext.ground, from: region, in: relativeArea, into: &existingMaterialOverrides)
        importMaterialOverrides(over: area, for: MaterialOverrideContext.leftElevation, from: region, in: relativeArea, into: &existingMaterialOverrides)
        importMaterialOverrides(over: area, for: MaterialOverrideContext.rightElevation, from: region, in: relativeArea, into: &existingMaterialOverrides)
    }
    
    private static func importMaterialOverrides(over area: MapArea, for context: MaterialOverrideContext, from region: MapRegionDescription, in relativeArea: MapArea, into existingMaterialOverrides: inout [String: [CustomSettings?]]?) {
        let key = context.rawValue
        guard let otherMaterialOverrides = region.materialOverrides?[key] else {
            return
        }
        
        for x in 0..<area.width {
            for y in 0..<area.height {
                guard relativeArea.contains(mapX: x, y: y) else {
                    continue
                }
                
                let otherX = x - relativeArea.x
                let otherY = y - relativeArea.y
                let otherIndex = otherY * relativeArea.width + otherX
                guard otherIndex >= 0, otherIndex < otherMaterialOverrides.count, let otherOverride = otherMaterialOverrides[otherIndex] else {
                    continue
                }
                
                if existingMaterialOverrides == nil {
                    existingMaterialOverrides = [key: []]
                }
                if existingMaterialOverrides![key] == nil {
                    existingMaterialOverrides![key] = []
                }
                var materialOverridesArray = existingMaterialOverrides![key]!
                let localIndex = y * area.width + x
                if materialOverridesArray.count < localIndex {
                    materialOverridesArray.append(contentsOf: [CustomSettings?](repeating: nil, count: localIndex - materialOverridesArray.count))
                }
                materialOverridesArray.append(otherOverride)
                existingMaterialOverrides![key] = materialOverridesArray
            }
        }
    }
    
    private static func importAssets(over area: MapArea, from other: MapRegionDescription, into existingAssetPlacements: inout [AssetPlacementDescription]) {
        for assetPlacement in other.assetPlacements {
            guard area.contains(mapPosition: assetPlacement.mapPosition) else { continue }
            existingAssetPlacements.append(assetPlacement)
        }
    }
    
}

fileprivate func changeAssetPlacementsElevation(placements: [AssetPlacementDescription], relativeElevation: Int) -> [AssetPlacementDescription] {
    placements.map { item in
        if item.mapPosition.elevation != nil {
            return item.with(newPosition: item.mapPosition.with(relativeElevation: relativeElevation))
        }
        return item
    }
}
