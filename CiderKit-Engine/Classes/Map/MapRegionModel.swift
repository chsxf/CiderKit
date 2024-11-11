import SpriteKit
import GameplayKit

public enum MapRegionErrors : Error {
    case assetTooCloseToRegionBorder
    case otherAssetInTheWay
}

public class MapRegionModel : Identifiable, Comparable {

    private static var nextRegionId: Int = 1
    
    public let id: Int

    public private(set) var regionDescription: MapRegionDescription

    weak var map: MapModel?

    public var elevation: Int { regionDescription.elevation }

    public init(with description: MapRegionDescription, in map: MapModel) {
        id = MapRegionModel.nextRegionId
        MapRegionModel.nextRegionId += 1
        
        self.regionDescription = description
        self.map = map
    }

    public func rename(to newName: String) {
        regionDescription.name = newName
    }

    func containsMapCoordinates(mapX x: Int, y: Int) -> Bool { regionDescription.area.contains(mapX: x, y: y) }

    public static func == (lhs: MapRegionModel, rhs: MapRegionModel) -> Bool {
        lhs.id == rhs.id
    }

    public static func < (lhs: MapRegionModel, rhs: MapRegionModel) -> Bool {
        let lhsArea = lhs.regionDescription.area
        let rhsArea = rhs.regionDescription.area
        
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
    
    public func increaseElevation() -> Bool {
        regionDescription.elevation += 1
        for assetPlacement in regionDescription.assetPlacements {
            if assetPlacement.mapPosition.elevation != nil {
                assetPlacement.mapPosition = assetPlacement.mapPosition.with(relativeElevation: 1)
            }
        }
        return true
    }
    
    public func decreaseElevation() -> Bool {
        var needsRebuilding = false
        if regionDescription.elevation > 0 {
            regionDescription.elevation -= 1
            for assetPlacement in regionDescription.assetPlacements {
                if assetPlacement.mapPosition.elevation != nil {
                    assetPlacement.mapPosition = assetPlacement.mapPosition.with(relativeElevation: -1)
                }
            }
            needsRebuilding = true
        }
        return needsRebuilding
    }
    
    public func subdivide(subArea: MapArea) -> (mainSubdivision: MapRegionModel, otherSubdivisions: [MapRegionModel])? {
        guard
            let map,
            let intersection = regionDescription.area.intersection(subArea)
        else {
            return nil
        }
        
        let hasLeftSubdiv = intersection.minX > regionDescription.area.minX
        let hasRightSubdiv = intersection.maxX < regionDescription.area.maxX
        let hasBottomSubdiv = intersection.minY > regionDescription.area.minY
        let hasTopSubdiv = intersection.maxY < regionDescription.area.maxY
        
        let mainSubdivDescription = MapRegionDescription(byExporting: intersection, from: regionDescription)
        let mainSubdivision = MapRegionModel(with: mainSubdivDescription, in: map)

        var otherSubdivisions = [MapRegionModel]()

        if hasLeftSubdiv {
            var area = regionDescription.area
            area.width = intersection.minX - area.minX
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: regionDescription)
            let otherMapRegion = MapRegionModel(with: otherSubdivDescription, in: map)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasRightSubdiv {
            var area = regionDescription.area
            area.width = area.maxX - intersection.maxX
            area.x = intersection.maxX
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: regionDescription)
            let otherMapRegion = MapRegionModel(with: otherSubdivDescription, in: map)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasTopSubdiv {
            let area = MapArea(x: intersection.minX, y: intersection.maxY, width: intersection.width, height: regionDescription.area.maxY - intersection.maxY)
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: regionDescription)
            let otherMapRegion = MapRegionModel(with: otherSubdivDescription, in: map)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasBottomSubdiv {
            let area = MapArea(x: intersection.minX, y: regionDescription.area.minY, width: intersection.width, height: intersection.minY - regionDescription.area.minY)
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: regionDescription)
            let otherMapRegion = MapRegionModel(with: otherSubdivDescription, in: map)
            otherSubdivisions.append(otherMapRegion)
        }
        
        return (mainSubdivision, otherSubdivisions)
    }

    public func isLocationValidAndFreeOfAssets(mapPosition: MapPosition, footprint: SIMD2<UInt32>) -> Bool {
        do {
            return try checkLocationPreconditions(mapPosition: mapPosition, footprint: footprint)
        }
        catch {
            return false
        }
    }

    private func checkLocationPreconditions(mapPosition: MapPosition, footprint: SIMD2<UInt32>) throws -> Bool {
        let localCoords = regionDescription.area.convert(fromMapPosition: mapPosition)
        let minimalFootprint = localCoords &+ IntPoint.one

        guard minimalFootprint.x >= footprint.x, minimalFootprint.y >= footprint.y else {
            throw MapRegionErrors.assetTooCloseToRegionBorder
        }

        let assetArea = MapArea(x: mapPosition.x - Int(footprint.x), y: mapPosition.y - Int(footprint.y), width: Int(footprint.x), height: Int(footprint.y))
        guard regionDescription.isFreeOfAsset(mapArea: assetArea) else {
            throw MapRegionErrors.otherAssetInTheWay
        }

        return true
    }

    public func add(assetPlacement: AssetPlacement) {
        regionDescription.assetPlacements.append(assetPlacement)
    }

    @discardableResult
    public func remove(assetPlacement: AssetPlacement) -> Bool {
        return removeAssetPlacement(with: assetPlacement.id)
    }

    @discardableResult
    public func removeAssetPlacement(with placementId: UUID) -> Bool {
        if regionDescription.assetPlacements.contains(where: { $0.id == placementId }) {
            regionDescription.assetPlacements.removeAll { $0.id == placementId }
            return true
        }
        return false
    }

}
