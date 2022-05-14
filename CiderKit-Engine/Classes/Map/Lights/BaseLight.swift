import Foundation
import SpriteKit

#if os(macOS)
import AppKit
public typealias LightColor = NSColor
#else
import UIKit
public typealias LightColor = UIColor
#endif

public class BaseLight: Codable {
    
    enum CodingKeys : String, CodingKey {
        case name = "n"
        case red = "r"
        case green = "g"
        case blue = "b"
        case positionX = "x"
        case positionY = "y"
        case positionZ = "z"
        case falloffNear = "fn"
        case falloffFar = "ff"
        case falloffExponent = "fe"
        case enabled = "e"
    }

    let color: LightColor

    var vector: vector_float3 { vector_float3(Float(color.redComponent), Float(color.greenComponent), Float(color.blueComponent)) }
    
    init(color: LightColor) {
        self.color = color
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let red = (try? container.decode(Float.self, forKey: CodingKeys.red)) ?? 0
        let green = (try? container.decode(Float.self, forKey: CodingKeys.green)) ?? 0
        let blue = (try? container.decode(Float.self, forKey: CodingKeys.blue)) ?? 0
        color = LightColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(Float(color.redComponent), forKey: CodingKeys.red)
        try container.encode(Float(color.greenComponent), forKey: CodingKeys.green)
        try container.encode(Float(color.blueComponent), forKey: CodingKeys.blue)
    }
    
}
