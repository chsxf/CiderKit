import Foundation
import CiderKitMacros

@MutableStruct(versioned: .internal)
public struct MapRegionDescription: Codable, Sendable, Identifiable, Comparable {

    private enum CodingKeys: String, CodingKey {
        case name, id, area, elevation, renderer, materialOverrides, assetPlacements
    }

    private enum MaterialOverrideContext: String {
        case ground = "g"
        case leftElevation = "l"
        case rightElevation = "r"
    }

    private static var internalNextRegionId: UInt = 0
    private static var nextRegionId: UInt {
        get {
            internalNextRegionId += 1
            return internalNextRegionId
        }
    }

    @MutatingProperty public let name: String?

    @MutableStructOptional(defaultValue: "Self.nextRegionId") public let id: UInt

    public let area: MapArea
    public let elevation: Int
    
    public let renderer: String?
    public let materialOverrides: [String: [CustomSettings?]]?
    
    public let assetPlacements: [AssetPlacementDescription]
    
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
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decodeIfPresent(String.self, forKey: .name)
        id = try container.decode(UInt.self, forKey: .id)
        area = try container.decode(MapArea.self, forKey: .area)
        elevation = try container.decode(Int.self, forKey: .elevation)
        renderer = try container.decodeIfPresent(String.self, forKey: .renderer)
        materialOverrides = try container.decodeIfPresent([String: [CustomSettings?]].self, forKey: .materialOverrides)
        assetPlacements = try container.decode([AssetPlacementDescription].self, forKey: .assetPlacements)

        version = 0
        Self.internalNextRegionId = max(id, Self.internalNextRegionId)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let name {
            try container.encode(name, forKey: .name)
        }
        try container.encode(id, forKey: .id)
        try container.encode(area, forKey: .area)
        try container.encode(elevation, forKey: .elevation)
        if let renderer {
            try container.encode(renderer, forKey: .renderer)
        }
        if let materialOverrides {
            try container.encode(materialOverrides, forKey: .materialOverrides)
        }
        try container.encode(assetPlacements, forKey: .assetPlacements)
    }

    public func checkLocationOccupancy(mapPosition: MapPosition, footprint: SIMD2<UInt32>) throws {
        guard area.contains(mapPosition: mapPosition) else {
            throw MapRegionErrors.assetOutside
        }

        let localCoords = area.convert(fromMapPosition: mapPosition)
        let minimalFootprint = localCoords &+ IntPoint.one
        guard minimalFootprint.x >= footprint.x, minimalFootprint.y >= footprint.y else {
            throw MapRegionErrors.assetTooCloseToRegionBorder
        }

        let assetArea = MapArea(x: mapPosition.x - Int(footprint.x), y: mapPosition.y - Int(footprint.y), width: Int(footprint.x), height: Int(footprint.y))
        guard isFreeOfAsset(mapArea: assetArea) else {
            throw MapRegionErrors.otherAssetInTheWay
        }
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
    
    public func elevated(by relativeElevation: Int) -> MapRegionDescription? {
        let newElevation = max(0, elevation + relativeElevation)
        guard elevation != newElevation else { return nil }
        
        let newAssetPlacements = changeAssetPlacementsElevation(placements: assetPlacements, relativeElevation: relativeElevation)
        return MapRegionDescription(name: name, area: area, elevation: newElevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: newAssetPlacements, version: version + 1)
    }
    
    public func withAssetPlacement(added newAssetPlacement: AssetPlacementDescription) -> MapRegionDescription {
        var newAssetPlacements = assetPlacements;
        newAssetPlacements.append(newAssetPlacement)
        return MapRegionDescription(name: name, area: area, elevation: elevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: newAssetPlacements, version: version)
    }
    
    public func withAssetPlacement(updated updatedAssetPlacement: AssetPlacementDescription) -> MapRegionDescription {
        for i in 0..<assetPlacements.count {
            let placement = assetPlacements[i]
            if placement.id == updatedAssetPlacement.id {
                var newAssetPlacements = assetPlacements
                newAssetPlacements[i] = updatedAssetPlacement
                return MapRegionDescription(name: name, area: area, elevation: elevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: newAssetPlacements, version: version)
            }
        }
        return self
    }
    
    public func withAssetPlacement(removed assetPlacementId: UUID) -> MapRegionDescription? {
        let newAssetPlacements = assetPlacements.compactMap { $0.id != assetPlacementId ? $0 : nil }
        if newAssetPlacements.count != assetPlacements.count {
            return MapRegionDescription(name: name, area: area, elevation: elevation, renderer: renderer, materialOverrides: materialOverrides, assetPlacements: newAssetPlacements, version: version)
        }
        return nil
    }
    
    public func subdivide(subArea: MapArea) -> (mainSubdivision: MapRegionDescription, otherSubdivisions: [MapRegionDescription])? {
        guard let intersection = area.intersection(subArea) else {
            return nil
        }
        
        let hasLeftSubdiv = intersection.minX > area.minX
        let hasRightSubdiv = intersection.maxX < area.maxX
        let hasBottomSubdiv = intersection.minY > area.minY
        let hasTopSubdiv = intersection.maxY < area.maxY
        
        let mainSubdivDescription = MapRegionDescription(byExporting: intersection, from: self)

        var otherSubdivisions = [MapRegionDescription]()

        if hasLeftSubdiv {
            var area = area
            area.width = intersection.minX - area.minX
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: self)
            otherSubdivisions.append(otherSubdivDescription)
        }
        
        if hasRightSubdiv {
            var area = area
            area.width = area.maxX - intersection.maxX
            area.x = intersection.maxX
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: self)
            otherSubdivisions.append(otherSubdivDescription)
        }
        
        if hasTopSubdiv {
            let area = MapArea(x: intersection.minX, y: intersection.maxY, width: intersection.width, height: area.maxY - intersection.maxY)
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: self)
            otherSubdivisions.append(otherSubdivDescription)
        }
        
        if hasBottomSubdiv {
            let area = MapArea(x: intersection.minX, y: area.minY, width: intersection.width, height: intersection.minY - area.minY)
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: self)
            otherSubdivisions.append(otherSubdivDescription)
        }
        
        return (mainSubdivDescription, otherSubdivisions)
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
    
    public static func == (lhs: MapRegionDescription, rhs: MapRegionDescription) -> Bool {
        lhs.id == rhs.id
    }
    
    public static func < (lhs: MapRegionDescription, rhs: MapRegionDescription) -> Bool {
        let lhsArea = lhs.area
        let rhsArea = rhs.area
        
        let regionsOverlapOnX = (lhsArea.maxX > rhsArea.minX && lhsArea.minX < rhsArea.maxX)
        let regionsOverlapOnY = (lhsArea.maxY > rhsArea.minY && lhsArea.minY < rhsArea.maxY)
        
        var result: Bool
        if regionsOverlapOnX {
            result = lhsArea.minY < rhsArea.minY
        }
        else if regionsOverlapOnY {
            result = lhsArea.minX < rhsArea.minX
        }
        else {
            result = (lhsArea.minX + lhsArea.minY) < (rhsArea.minX + rhsArea.minY)
        }
        return result
    }

    static func resetInternalRegionId() {
        Self.internalNextRegionId = 0
    }
}

fileprivate func changeAssetPlacementsElevation(placements: [AssetPlacementDescription], relativeElevation: Int) -> [AssetPlacementDescription] {
    placements.map { item in
        if item.mapPosition.elevation != nil {
            return item.mutated(withMapPosition: item.mapPosition.with(relativeElevation: relativeElevation))
        }
        return item
    }
}
