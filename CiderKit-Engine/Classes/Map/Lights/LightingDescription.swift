import Foundation
import CoreGraphics

struct LightingDescription: Codable {

    enum LightDescriptionDecodingError: Error {
        case unknownLightType(String)
    }

    enum CodingKeys: CodingKey {
        case ambientLight
        case lights
    }

    let ambientLight: BaseLight
    var lights: [BaseLight]

    init(ambientLight: BaseLight? = nil) {
        self.ambientLight = ambientLight ?? BaseLight(color: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        lights = []
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ambientLightContainer = try container.nestedContainer(keyedBy: BaseLight.CodingKeys.self, forKey: .ambientLight)
        self.ambientLight = try BaseLight(from: ambientLightContainer)
        lights = []
        var lightsContainer = try container.nestedUnkeyedContainer(forKey: .lights)
        while !lightsContainer.isAtEnd {
            let lightContainer = try lightsContainer.nestedContainer(keyedBy: BaseLight.CodingKeys.self)
            let type = (try? lightContainer.decode(String.self, forKey: .type)) ?? "point"
            if type == "point" {
                lights.append(try PointLight(from: lightContainer))
            }
            else if type == "directional" {
                lights.append(try DirectionalLight(from: lightContainer))
            }
            else {
                throw LightDescriptionDecodingError.unknownLightType(type)
            }
        }
    }

}
