import Foundation
import CoreGraphics
import CiderKitMacros

@MutableStruct(versioned: .internal)
struct LightingDescription: Codable, Sendable {

    enum LightDescriptionDecodingError: Error {
        case unknownLightType(String)
    }

    enum CodingKeys: CodingKey {
        case ambientLight
        case lights
    }

    @MutatingProperty let ambientLight: AmbientLightDescription
    @MutatingProperty(accessLevel: .private) let lights: [any LightDescriptor]

    init(ambientLight: AmbientLightDescription? = nil, lights: [any LightDescriptor] = []) {
        self.ambientLight = ambientLight ?? AmbientLightDescription(color: CGColor.white)
        self.lights = lights
        version = 0
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ambientLightContainer = try container.nestedContainer(keyedBy: LightDescriptorCodingKeys.self, forKey: .ambientLight)
        self.ambientLight = try AmbientLightDescription(from: ambientLightContainer)
        var lightsBuffer = [any LightDescriptor]()
        var lightsContainer = try container.nestedUnkeyedContainer(forKey: .lights)
        while !lightsContainer.isAtEnd {
            let lightContainer = try lightsContainer.nestedContainer(keyedBy: LightDescriptorCodingKeys.self)
            let type = (try? lightContainer.decode(String.self, forKey: .type)) ?? "point"
            if type == "point" {
                lightsBuffer.append(try PointLightDescription(from: lightContainer))
            }
            else if type == "directional" {
                lightsBuffer.append(try DirectionalLightDescription(from: lightContainer))
            }
            else {
                throw LightDescriptionDecodingError.unknownLightType(type)
            }
        }
        lights = lightsBuffer

        version = 0
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ambientLight, forKey: .ambientLight)
        
        var lightsContainer = container.nestedUnkeyedContainer(forKey: .lights)
        for light in lights {
            try lightsContainer.encode(light)
        }
    }

    func add(light: any LightDescriptor) -> Self {
        guard lights.contains(where: { $0.id == light.id }) == false else {
            return self
        }

        var newLights = lights
        newLights.append(light)
        return mutated(withLights: newLights)
    }

    func removeLight(by id: UUID) -> Self {
        var newLights = lights
        let countBefore = newLights.count
        newLights.removeAll { $0.id == id }
        if newLights.count != countBefore {
            return mutated(withLights: newLights)
        }
        return self
    }

}
