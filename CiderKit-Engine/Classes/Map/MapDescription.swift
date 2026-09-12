import Foundation
import CiderKitMacros

@MutableStruct(initAccessLevel: .internal)
public struct MapDescription: Codable, Sendable {
    @MutatingProperty let regions: [MapRegionDescription]
    @MutatingProperty let lighting: LightingDescription
    @MutatingProperty let renderers: [String:CellRendererDescription]

    init() {
        regions = []
        lighting = LightingDescription()
        renderers = [:]
    }
}
