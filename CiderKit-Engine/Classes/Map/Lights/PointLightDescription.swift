import SpriteKit
import CiderKitMacros

@MutableStruct
public struct PointLightDescription: LightDescriptor {

    @MutableStruct
    public struct Falloff: Sendable {
        @MutatingProperty public let near: Float
        @MutatingProperty public let far: Float
        @MutatingProperty public let exponent: Float
        
        var vector: SIMD3<Float> { SIMD3(near, far, exponent) }
    }
    
    @MutableStructOptional(defaultValue: "UUID()") public let id: UUID
    @MutatingProperty public let color: CGColor
    public let type: String = "point"
    
    @MutatingProperty public let enabled: Bool
    @MutatingProperty public let name: String
    @MutatingProperty public let position: WorldPosition
    @MutatingProperty public let falloff: Falloff
    
    public init() {
        id = UUID()
        color = CGColor.white
        enabled = true
        name = ""
        position = WorldPosition()
        falloff = Falloff(near: 0, far: 5, exponent: 0.5)
    }
    
    public init(from container: KeyedDecodingContainer<LightDescriptorCodingKeys>) throws {
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        
        let colorComponents = try container.decode(SIMD3<Float>.self, forKey: .color)
        color = CGColor(red: CGFloat(colorComponents.x), green: CGFloat(colorComponents.y), blue: CGFloat(colorComponents.z), alpha: 1)
        
        enabled = try container.decode(Bool.self, forKey: .enabled)
        name = try container.decode(String.self, forKey: .name)

        position = try container.decode(WorldPosition.self, forKey: .position)

        let near = (try? container.decode(Float.self, forKey: .falloffNear)) ?? 0
        let far = (try? container.decode(Float.self, forKey: .falloffFar)) ?? 1
        let exponent = (try? container.decode(Float.self, forKey: .falloffExponent)) ?? 1
        falloff = Falloff(near: near, far: far, exponent: exponent)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: LightDescriptorCodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(colorVector, forKey: .color)

        try container.encode(enabled, forKey: .enabled)
        try container.encode(name, forKey: .name)
        
        try container.encode(position, forKey: .position)

        try container.encode(falloff.near, forKey: .falloffNear)
        try container.encode(falloff.far, forKey: .falloffFar)
        try container.encode(falloff.exponent, forKey: .falloffExponent)
    }
    
    public func toImplementation() -> some LightImplementation {
        PointLight(from: self)
    }
    
}
