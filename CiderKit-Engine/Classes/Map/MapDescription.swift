import Foundation

public struct MapDescription: Codable {
    var regions: [MapRegionDescription]
    var lighting: LightingDescription
    var renderers: [String:CellRendererDescription]
    
    init() {
        regions = []
        lighting = LightingDescription()
        renderers = [:]
    }
}
