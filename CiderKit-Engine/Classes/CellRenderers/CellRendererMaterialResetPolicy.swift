import Foundation

public enum CellRendererMaterialResetPolicy: Int, Codable, Sendable {
    case inherit = 0
    case resetWithEachCell = 1
    case resetWithEachRegion = 2
    case resetAlways = 3
}
