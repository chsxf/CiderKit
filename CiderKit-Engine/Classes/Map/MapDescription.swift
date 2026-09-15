import Foundation
import CiderKitMacros

@MutableStruct(initAccessLevel: .internal, versioned: .internal)
public struct MapDescription: Codable, Sendable {
    @MutableStructOptional(defaultValue: "UUID()") let id: UUID
    @MutatingProperty let regions: [MapRegionDescription]
    @MutatingProperty let lighting: LightingDescription
    @MutatingProperty let renderers: [String:CellRendererDescription]

    init() {
        id = UUID()
        regions = []
        lighting = LightingDescription()
        renderers = [:]
        version = 0
    }

    public func regionAt(mapX x: Int, y: Int) -> MapRegionDescription? {
        regions.first(where: { $0.area.contains(mapX: x, y: y) })
    }

    public func regionAt(mapPosition position: MapPosition) -> MapRegionDescription? {
        regionAt(mapX: position.x, y: position.y)
    }

    public func hasCell(forMapX x: Int, y: Int) -> Bool {
        regionAt(mapX: x, y: y) != nil
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
        regionAt(mapX: x, y: y)?.elevation
    }

    public func getAssetPlacement(by id: UUID) -> AssetPlacementDescription? {
        for region in regions {
            if let placement = region.assetPlacements.first(where: { $0.id == id }) {
                return placement
            }
        }
        return nil
    }
}
