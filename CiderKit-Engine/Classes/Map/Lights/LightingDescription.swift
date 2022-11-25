import Foundation
import CoreGraphics

struct LightingDescription: Codable {
    
    let ambientLight: BaseLight
    var lights: [PointLight]

    init(ambientLight: BaseLight? = nil) {
        self.ambientLight = ambientLight ?? BaseLight(color: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        lights = []
    }
    
}
