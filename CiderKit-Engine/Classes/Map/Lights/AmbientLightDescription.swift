import SpriteKit
import CiderKitMacros

@MutableStruct
public struct AmbientLightDescription: LightDescriptor {
    public static let AMBIENT_LIGHT_UUID = "11111111-1111-1111-1111-111111111111"
    
    public let id = UUID(uuidString: Self.AMBIENT_LIGHT_UUID)!
    public let type = "ambient"
    @MutatingProperty public let color: CGColor
    
    public init() {
        self.init(color: CGColor.white)
    }
    
    public init(color: CGColor) {
        self.color = color.toRGB() ?? CGColor(red: 0, green: 0, blue: 0, alpha: 0);
    }
    
    public init(from container: KeyedDecodingContainer<LightDescriptorCodingKeys>) throws {
        let colorComponents = try container.decode(SIMD3<Float>.self, forKey: .color)
        color = CGColor(red: CGFloat(colorComponents.x), green: CGFloat(colorComponents.y), blue: CGFloat(colorComponents.z), alpha: 1)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: LightDescriptorCodingKeys.self)

        try container.encode(type, forKey: .type)
        try container.encode(colorVector, forKey: .color)
    }
    
    public func toImplementation() -> some LightImplementation {
        AmbientLight(from: self)
    }
    
}
