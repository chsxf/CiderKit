import Foundation

public struct MapDescription: Codable, Sendable {
    let regions: [MapRegionDescription]
    let lighting: LightingDescription
    let renderers: [String:CellRendererDescription]
}
