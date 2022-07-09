import Foundation
import SpriteKit

public class BaseLight: Codable, ObservableObject {
    
    enum CodingKeys : String, CodingKey {
        case name = "n"
        case red = "r"
        case green = "g"
        case blue = "b"
        case positionX = "x"
        case positionY = "y"
        case elevation = "z"
        case falloffNear = "fn"
        case falloffFar = "ff"
        case falloffExponent = "fe"
        case enabled = "e"
    }

    @Published public var color: CGColor

    var vector: vector_float3 { vector_float3(Float(color.components![0]), Float(color.components![1]), Float(color.components![2])) }
    
    init(color: CGColor) {
        self.color = color
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let red = (try? container.decode(Float.self, forKey: CodingKeys.red)) ?? 0
        let green = (try? container.decode(Float.self, forKey: CodingKeys.green)) ?? 0
        let blue = (try? container.decode(Float.self, forKey: CodingKeys.blue)) ?? 0
        color = CGColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(Float(color.components![0]), forKey: CodingKeys.red)
        try container.encode(Float(color.components![1]), forKey: CodingKeys.green)
        try container.encode(Float(color.components![2]), forKey: CodingKeys.blue)
    }
    
}
