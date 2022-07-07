import Foundation

struct LightingDescription: Codable {
    
    let ambientLight: BaseLight?
    let lights: [PointLight]?
    
}
