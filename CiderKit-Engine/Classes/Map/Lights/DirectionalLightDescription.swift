import SpriteKit
import CiderKitMacros

@MutableStruct
public struct DirectionalLightDescription: LightDescriptor {
    @MutableStructOptional(defaultValue: "UUID()") public let id: UUID
    public let type: String = "directional"
    @MutatingProperty public let color: CGColor
    
    @MutatingProperty public let enabled: Bool
    @MutatingProperty public let name: String
    @MutatingProperty public let position: WorldPosition
    @MutatingProperty public let orientation: SIMD2<Float> // declination, right ascension
    
    public init() {
        id = UUID()
        color = CGColor.white
        enabled = true
        name = ""
        position = WorldPosition()
        orientation = SIMD2()
    }
    
    public init(name: String, color: CGColor, position: SIMD3<Float>, orientation: SIMD2<Float>) {
        id = UUID()
        self.color = color
        enabled = true
        self.name = name
        self.position = position
        self.orientation = orientation
    }

    public init(from container: KeyedDecodingContainer<LightDescriptorCodingKeys>) throws {
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        
        let colorComponents = try container.decode(SIMD3<Float>.self, forKey: .color)
        color = CGColor(red: CGFloat(colorComponents.x), green: CGFloat(colorComponents.y), blue: CGFloat(colorComponents.z), alpha: 1)
        
        enabled = try container.decode(Bool.self, forKey: .enabled)
        name = try container.decode(String.self, forKey: .name)

        position = try container.decode(WorldPosition.self, forKey: .position)
        orientation = try container.decode(SIMD2<Float>.self, forKey: .orientation)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: LightDescriptorCodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(colorVector, forKey: .color)
        
        try container.encode(enabled, forKey: .enabled)
        try container.encode(name, forKey: .name)

        try container.encode(position, forKey: .position)
        try container.encode(orientation, forKey: .orientation)
    }
    
    public func toImplementation() -> some LightImplementation {
        DirectionalLight(from: self)
    }
    
}
