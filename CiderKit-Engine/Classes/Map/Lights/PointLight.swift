import Foundation
import SpriteKit

public class PointLight: BaseLight {
    
    public struct Falloff {
        public var near: Float
        public var far: Float
        public var exponent: Float
        
        var vector: vector_float3 { vector_float3(near, far, exponent) }
    }
    
    public var enabled: Bool
    public var name: String
    public var position: vector_float3
    public var falloff: Falloff
 
    var matrix: matrix_float3x3 {
        get {
            var falloffVector = falloff.vector
            if !enabled {
                falloffVector.y = 0
            }
            return matrix_float3x3([position * vector_float3(1, 1, 0.25), vector, falloffVector])
        }
    }
    
    init(name: String, color: LightColor, position: vector_float3, falloff: Falloff) {
        enabled = true
        self.name = name
        self.position = position
        self.falloff = falloff
        super.init(color: color)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        enabled = (try? container.decode(Bool.self, forKey: CodingKeys.enabled)) ?? true
        name = (try? container.decode(String.self, forKey: CodingKeys.name)) ?? "PointLight"
        
        let x = (try? container.decode(Float.self, forKey: CodingKeys.positionX)) ?? 0
        let y = (try? container.decode(Float.self, forKey: CodingKeys.positionY)) ?? 0
        let z = ((try? container.decode(Float.self, forKey: CodingKeys.positionZ)) ?? 0)
        position = vector_float3(x, y, z)
        
        let near = (try? container.decode(Float.self, forKey: CodingKeys.falloffNear)) ?? 0
        let far = (try? container.decode(Float.self, forKey: CodingKeys.falloffFar)) ?? 1
        let exponent = (try? container.decode(Float.self, forKey: CodingKeys.falloffExponent)) ?? 1
        falloff = Falloff(near: near, far: far, exponent: exponent)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(enabled, forKey: CodingKeys.enabled)
        try container.encode(name, forKey: CodingKeys.name)
        
        try container.encode(position.x, forKey: CodingKeys.positionX)
        try container.encode(position.y, forKey: CodingKeys.positionY)
        try container.encode(position.z, forKey: CodingKeys.positionZ)
        
        try container.encode(falloff.near, forKey: CodingKeys.falloffNear)
        try container.encode(falloff.far, forKey: CodingKeys.falloffFar)
        try container.encode(falloff.exponent, forKey: CodingKeys.falloffExponent)
    }
    
}
