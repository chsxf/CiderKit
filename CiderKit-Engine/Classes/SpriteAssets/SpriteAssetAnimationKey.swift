import SpriteKit

public enum SpriteAssetAnimationKeyError: Error {
    case noDefinedValue
}

public class SpriteAssetAnimationKey: Codable {
    
    enum CodingKeys: String, CodingKey {
        case frame = "frame"
        case bool = "b"
        case float = "f"
        case color = "c"
        case string = "s"
        case maintainValue = "m"
        case timingInterpolation = "i"
    }
    
    enum ColorCodingKeys: String, CodingKey {
        case colorSpaceName = "csn"
        case components = "cmp"
    }
    
    public var frame: Int
    
    public var boolValue: Bool? = nil
    public var floatValue: Float? = nil
    public var colorValue: CGColor? = nil
    public var stringValue: String? = nil
    
    public var maintainValue: Bool = false
    public var timingInterpolation: SKActionTimingMode = .linear
    
    public init(frame: Int) {
        self.frame = frame
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        frame = try container.decode(Int.self, forKey: .frame)
        maintainValue = try container.decode(Bool.self, forKey: .maintainValue)
        timingInterpolation = SKActionTimingMode(rawValue: try container.decode(Int.self, forKey: .timingInterpolation))!
        
        if container.contains(.bool) {
            boolValue = try container.decode(Bool.self, forKey: .bool)
        }
        else if container.contains(.float) {
            floatValue = try container.decode(Float.self, forKey: .float)
        }
        else if container.contains(.color) {
            let colorContainer = try container.nestedContainer(keyedBy: ColorCodingKeys.self, forKey: .color)
            let colorSpaceName = try colorContainer.decode(String.self, forKey: .colorSpaceName)
            var componentsContainer = try colorContainer.nestedUnkeyedContainer(forKey: .components)
            var components = [CGFloat]()
            while !componentsContainer.isAtEnd {
                components.append(try componentsContainer.decode(CGFloat.self))
            }
            colorValue = CGColor(colorSpace: CGColorSpace(name: colorSpaceName as CFString)!, components: components)!
        }
        else if container.contains(.string) {
            stringValue = try container.decode(String.self, forKey: .string)
        }
        else {
            throw SpriteAssetAnimationKeyError.noDefinedValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(frame, forKey: .frame)
        try container.encode(maintainValue, forKey: .maintainValue)
        try container.encode(timingInterpolation.rawValue, forKey: .timingInterpolation)
        
        if let boolValue = boolValue {
            try container.encode(boolValue, forKey: .bool)
        }
        else if let floatValue = floatValue {
            try container.encode(floatValue, forKey: .float)
        }
        else if let colorValue = colorValue {
            var colorContainer = container.nestedContainer(keyedBy: ColorCodingKeys.self, forKey: .color)
            let colorSpaceName = colorValue.colorSpace!.name! as String
            try colorContainer.encode(colorSpaceName, forKey: .colorSpaceName)
            var componentsContainer = colorContainer.nestedUnkeyedContainer(forKey: .components)
            for component in colorValue.components! {
                try componentsContainer.encode(component)
            }
        }
        else if let stringValue = stringValue {
            try container.encode(stringValue, forKey: .string)
        }
        else {
            throw SpriteAssetAnimationKeyError.noDefinedValue
        }
    }

    class func getInterpolatedValue(for trackType: SpriteAssetAnimationTrackType, at frame: Int, from firstKey: SpriteAssetAnimationKey?, to secondKey: SpriteAssetAnimationKey?) -> Any? {
        let firstKeyMaintainsValue = firstKey?.maintainValue ?? false
        
        if firstKey == nil {
            switch trackType {
            case .visibility:
                return secondKey?.boolValue
            case .color:
                return secondKey?.colorValue
            case .sprite:
                return secondKey?.stringValue
            default:
                return secondKey?.floatValue
            }
        }
        else if secondKey == nil || firstKeyMaintainsValue {
            switch trackType {
            case .visibility:
                return firstKey?.boolValue
            case .color:
                return firstKey?.colorValue
            case .sprite:
                return firstKey?.stringValue
            default:
                return firstKey?.floatValue
            }
        }
        else {
            if let firstKey = firstKey, let secondKey = secondKey {
                var interpolationRatio = Float(frame - firstKey.frame) / Float(secondKey.frame - firstKey.frame)
                switch firstKey.timingInterpolation {
                case .linear:
                    interpolationRatio = linearInterpolationFunction(time: interpolationRatio)
                case .easeIn:
                    interpolationRatio = easeInInterpolationFunction(time: interpolationRatio)
                case .easeOut:
                    interpolationRatio = easeOutInterpolationFunction(time: interpolationRatio)
                case .easeInEaseOut:
                    interpolationRatio = easeInEaseOutInterpolationFunction(time: interpolationRatio)
                @unknown default:
                    break
                }

                switch trackType {
                case .visibility:
                    return firstKey.boolValue
                case .color:
                    if let firstValue = firstKey.colorValue, let secondValue = secondKey.colorValue {
                        return CGColor.interpolateRGB(from: firstValue, to: secondValue, t: interpolationRatio)
                    }
                case .sprite:
                    return firstKey.stringValue
                default:
                    if let firstValue = firstKey.floatValue, let secondValue = secondKey.floatValue {
                        return simd_mix(firstValue, secondValue, interpolationRatio)
                    }
                }
            }
            return nil
        }
    }
    
    public class func linearInterpolationFunction(time: Float) -> Float { time }
    
    public class func easeInInterpolationFunction(time: Float) -> Float { pow(time, 0.5) }
    
    public class func easeOutInterpolationFunction(time: Float) -> Float { 1.0 - pow(1.0 - time, 0.5) }
    
    public class func easeInEaseOutInterpolationFunction(time: Float) -> Float {
        if time < 0.5 {
            return pow(time * 2.0, 0.5) * 0.5
        }
        else {
            return 1.0 - pow(1.0 - (time - 0.5) * 2.0, 0.5) * 0.5
        }
    }
    
}
