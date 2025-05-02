import Foundation
import SpriteKit

public class BaseLight: Encodable, ObservableObject {

    public enum CodingKeys : String, CodingKey {
        case type = "t"
        case name = "n"
        case color = "c"
        case position = "p"
        case orientation = "o"
        case falloffNear = "fn"
        case falloffFar = "ff"
        case falloffExponent = "fe"
        case enabled = "e"
    }

    @Published public var color: CGColor

    open var type: String { "base" }
    open var matrix: matrix_float3x3 { fatalError("Missing implementation") }

    var colorVector: SIMD3<Float> { SIMD3(Float(color.components![0]), Float(color.components![1]), Float(color.components![2])) }
    
    init(color: CGColor) {
        self.color = color.toRGB()!
    }
    
    public required init(from container: KeyedDecodingContainer<CodingKeys>) throws {
        let colorComponents = try container.decode(SIMD3<Float>.self, forKey: .color)
        color = CGColor(red: CGFloat(colorComponents.x), green: CGFloat(colorComponents.y), blue: CGFloat(colorComponents.z), alpha: 1)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(type, forKey: .type)
        try container.encode(colorVector, forKey: .color)
    }
    
}
