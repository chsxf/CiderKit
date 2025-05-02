import Foundation
import SpriteKit

public class PointLight: BaseLight, NamedObject {

    public struct Falloff {
        public var near: Float
        public var far: Float
        public var exponent: Float
        
        var vector: SIMD3<Float> { SIMD3(near, far, exponent) }

        public init(near: Float, far: Float, exponent: Float) {
            self.near = near
            self.far = far
            self.exponent = exponent
        }
    }

    @Published public var enabled: Bool
    @Published public var name: String
    @Published public var position: WorldPosition
    @Published public var falloff: Falloff

    public override var type: String { "point" }

    public override var matrix: matrix_float3x3 {
        get {
            var falloffVector = falloff.vector
            if !enabled {
                falloffVector.y = 0
            }
            return matrix_float3x3([colorVector, position, falloffVector])
        }
    }
    
    public init(name: String, color: CGColor, position: WorldPosition, falloff: Falloff) {
        enabled = true
        self.name = name
        self.position = position
        self.falloff = falloff
        super.init(color: color)
    }
    
    required init(from container: KeyedDecodingContainer<CodingKeys>) throws {
        enabled = try container.decode(Bool.self, forKey: .enabled)
        name = try container.decode(String.self, forKey: .name)

        position = try container.decode(WorldPosition.self, forKey: .position)

        let near = (try? container.decode(Float.self, forKey: .falloffNear)) ?? 0
        let far = (try? container.decode(Float.self, forKey: .falloffFar)) ?? 1
        let exponent = (try? container.decode(Float.self, forKey: .falloffExponent)) ?? 1
        falloff = Falloff(near: near, far: far, exponent: exponent)
        
        try super.init(from: container)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(enabled, forKey: .enabled)
        try container.encode(name, forKey: .name)
        
        try container.encode(position, forKey: .position)

        try container.encode(falloff.near, forKey: .falloffNear)
        try container.encode(falloff.far, forKey: .falloffFar)
        try container.encode(falloff.exponent, forKey: .falloffExponent)
    }
    
}
