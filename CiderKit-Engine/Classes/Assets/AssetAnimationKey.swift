import SpriteKit
import CiderKit_Tween

public enum AssetAnimationKeyError: Error {
    case noDefinedValue
}

public final class AssetAnimationKey: Codable {
    
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
    
    public var frame: UInt
    
    public private(set) var boolValue: Bool? = nil
    public private(set) var floatValue: Float? = nil
    public private(set) var colorValue: CGColor? = nil
    public private(set) var stringValue: String? = nil
    
    public var maintainValue: Bool = false
    public var timingInterpolation: Easing = .linear

    public var time: TimeInterval { AssetAnimationTrack.frameTime * Double(frame) }
    
    public init(frame: UInt, boolValue: Bool) {
        self.frame = frame
        self.boolValue = boolValue
    }
    
    public init(frame: UInt, floatValue: Float) {
        self.frame = frame
        self.floatValue = floatValue
    }
    
    public init(frame: UInt, colorValue: CGColor) {
        self.frame = frame
        self.colorValue = colorValue
    }
    
    public init(frame: UInt, stringValue: String) {
        self.frame = frame
        self.stringValue = stringValue
    }
    
    public func set(boolValue: Bool) {
        self.boolValue = boolValue
        floatValue = nil
        colorValue = nil
        stringValue = nil
    }
    
    public func set(floatValue: Float) {
        self.floatValue = floatValue
        boolValue = nil
        colorValue = nil
        stringValue = nil
    }
    
    public func set(colorValue: CGColor) {
        self.colorValue = colorValue
        boolValue = nil
        floatValue = nil
        stringValue = nil
    }
    
    public func set(stringValue: String) {
        self.stringValue = stringValue
        boolValue = nil
        floatValue = nil
        colorValue = nil
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        frame = try container.decode(UInt.self, forKey: .frame)
        maintainValue = try container.decode(Bool.self, forKey: .maintainValue)
        timingInterpolation = try container.decode(Easing.self, forKey: .timingInterpolation)
        
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
            throw AssetAnimationKeyError.noDefinedValue
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
            throw AssetAnimationKeyError.noDefinedValue
        }
    }

    class func getInterpolatedValue(at frame: UInt, from firstKey: AssetAnimationKey?, to secondKey: AssetAnimationKey?) -> Any? {
        let firstKeyMaintainsValue = firstKey?.maintainValue ?? false
        
        if firstKey == nil {
            return secondKey?.boolValue ?? secondKey?.colorValue ?? secondKey?.stringValue ?? secondKey?.floatValue
        }
        else if secondKey == nil || firstKeyMaintainsValue {
            return firstKey?.boolValue ?? firstKey?.colorValue ?? firstKey?.stringValue ?? firstKey?.floatValue
        }
        else {
            if let firstKey, let secondKey {
                let interpolationRatio = Float(frame - firstKey.frame) / Float(secondKey.frame - firstKey.frame)
                return Self.getInterpolatedValue(ratio: interpolationRatio, from: firstKey, to: secondKey)
            }
            return nil
        }
    }
    
    class func getInterpolatedValue(ratio: Float, from firstKey: AssetAnimationKey, to secondKey: AssetAnimationKey) -> Any? {
        guard ratio >= 0 && ratio <= 1 else { return nil }
        
        if let firstKeyBoolValue = firstKey.boolValue {
            return firstKeyBoolValue
        }
        
        if let firstKeyStringValue = firstKey.stringValue {
            return firstKeyStringValue
        }
        
        let easingFunction = firstKey.timingInterpolation.easingFunction()
        let interpolationRatio = easingFunction(ratio)

        if let firstValue = firstKey.colorValue, let secondValue = secondKey.colorValue {
            return CGColor.interpolateRGB(from: firstValue, to: secondValue, t: interpolationRatio)
        }
        
        if let firstValue = firstKey.floatValue, let secondValue = secondKey.floatValue {
            return simd_mix(firstValue, secondValue, interpolationRatio)
        }
        
        return nil
    }
    
}
