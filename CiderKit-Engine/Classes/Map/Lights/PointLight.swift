import Foundation
import SpriteKit

public class PointLight: BaseLight {
    
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
    @Published public var position: SIMD3<Float>
    @Published public var falloff: Falloff
 
    var matrix: matrix_float3x3 {
        get {
            var falloffVector = falloff.vector
            if !enabled {
                falloffVector.y = 0
            }
            return matrix_float3x3([position, vector, falloffVector])
        }
    }
    
    public init(name: String, color: CGColor, position: SIMD3<Float>, falloff: Falloff) {
        enabled = true
        self.name = name
        self.position = position
        self.falloff = falloff
        super.init(color: color)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        enabled = (try? container.decode(Bool.self, forKey: .enabled)) ?? true
        name = (try? container.decode(String.self, forKey: .name)) ?? "PointLight"
        
        let x = (try? container.decode(Float.self, forKey: .positionX)) ?? 0
        let y = (try? container.decode(Float.self, forKey: .positionY)) ?? 0
        let z = ((try? container.decode(Float.self, forKey: .elevation)) ?? 0)
        position = SIMD3(x, y, z)
        
        let near = (try? container.decode(Float.self, forKey: .falloffNear)) ?? 0
        let far = (try? container.decode(Float.self, forKey: .falloffFar)) ?? 1
        let exponent = (try? container.decode(Float.self, forKey: .falloffExponent)) ?? 1
        falloff = Falloff(near: near, far: far, exponent: exponent)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(enabled, forKey: .enabled)
        try container.encode(name, forKey: .name)
        
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
        try container.encode(position.z, forKey: .elevation)
        
        try container.encode(falloff.near, forKey: .falloffNear)
        try container.encode(falloff.far, forKey: .falloffFar)
        try container.encode(falloff.exponent, forKey: .falloffExponent)
    }
    
}
