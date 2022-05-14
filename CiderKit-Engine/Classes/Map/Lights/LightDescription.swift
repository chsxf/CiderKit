import Foundation

struct LightDescription: Codable {
    
    let ambientLight: BaseLight?
    let lights: [PointLight]?
    
}
