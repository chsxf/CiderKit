import Foundation

struct CellRendererDescription: Codable, Sendable {
    enum CodingKeys: String, CodingKey {
        case groundMaterialName = "g"
        case leftElevationMaterialName = "l"
        case rightElevationMaterialName = "r"
        case resetPolicy = "rp"
    }
    
    let groundMaterialName: String
    let leftElevationMaterialName: String
    let rightElevationMaterialName: String
    let resetPolicy: CellRendererMaterialResetPolicy
    
}
