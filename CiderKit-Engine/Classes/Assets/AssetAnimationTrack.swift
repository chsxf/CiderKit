import SpriteKit

public enum AssetAnimationTrackError: Error {
    case invalidValueType
    case invalidFrame
    case duplicateKeyFrame
}

public final class AssetAnimationTrack: Codable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case keys
    }

    static let frameTime: TimeInterval = 1.0/60.0
    
    let type: AssetAnimationTrackType
    
    private var keys: [AssetAnimationKey]
    
    public var hasAnyKey: Bool { !keys.isEmpty }
    
    public var firstKey: AssetAnimationKey? { keys.first }
    public var lastKey: AssetAnimationKey? { keys.last }
    
    public var duration: TimeInterval {
        guard let lastKey else { return -1 }
        return Self.frameTime * TimeInterval(lastKey.frame + 1)
    }
    
    public init(type: AssetAnimationTrackType) {
        self.type = type
        keys = []
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = AssetAnimationTrackType.get(registered: try container.decode(String.self, forKey: .type))!
        
        keys = []
        var keyContainer = try container.nestedUnkeyedContainer(forKey: .keys)
        while !keyContainer.isAtEnd {
            keys.append(try keyContainer.decode(AssetAnimationKey.self))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type.name, forKey: .type)
        var keyContainer = container.nestedUnkeyedContainer(forKey: .keys)
        for key in keys {
            try keyContainer.encode(key)
        }
    }
    
    public func getValue(at frame: UInt, for element: TransformAssetElement? = nil) -> Any? {
        if !keys.isEmpty {
            if let key = getKey(at: frame) {
                return AssetAnimationKey.getInterpolatedValue(at: frame, from: key, to: nil)
            }
            
            var selectedKeyIndex: Int = keys.count
            for i in 0..<keys.count {
                let key = keys[i]
                if key.frame > frame {
                    selectedKeyIndex = i - 1
                    break
                }
            }
            
            if selectedKeyIndex < 0 {
                return AssetAnimationKey.getInterpolatedValue(at: frame, from: nil, to: keys.first)
            }
            else if selectedKeyIndex == keys.count {
                return AssetAnimationKey.getInterpolatedValue(at: frame, from: keys.last, to: nil)
            }
            else {
                return AssetAnimationKey.getInterpolatedValue(at: frame, from: keys[selectedKeyIndex], to: keys[selectedKeyIndex + 1])
            }
        }
        
        return element?[type]
    }
    
    public func hasKey(at frame: UInt) -> Bool { getKey(at: frame) != nil }
    
    public func getKey(at frame: UInt) -> AssetAnimationKey? {
        keys.first(where: { $0.frame == frame })
    }
    
    public func getNextKey(from frame: UInt) -> AssetAnimationKey? {
        keys.first(where: { $0.frame > frame })
    }
    
    public func getPrevKey(from frame: UInt) -> AssetAnimationKey? {
        keys.last(where: { $0.frame < frame })
    }
    
    public func removeKey(at frame: UInt) {
        keys.removeAll { $0.frame == frame }
    }
    
    public func setValue(_ value: Any, at frame: UInt) throws {
        switch value {
        case let b as Bool:
            try setBool(b, at: frame)
        case let c as CGFloat:
            try setFloat(Float(c), at: frame)
        case let f as Float:
            try setFloat(f, at: frame)
        case let s as String:
            try setString(s, at: frame)
        case let c as CGColor:
            try setColor(c, at: frame)
        default:
            throw AssetAnimationTrackError.invalidValueType
        }
    }
    
    public func setBool(_ value: Bool, at frame: UInt) throws {
        if let key = getKey(at: frame) {
            key.set(boolValue: value)
        }
        else {
            let newKey = AssetAnimationKey(frame: frame, boolValue: value)
            try addKey(newKey)
        }
    }
    
    public func setFloat(_ value: Float, at frame: UInt) throws {
        if let key = getKey(at: frame) {
            key.set(floatValue: value)
        }
        else {
            let newKey = AssetAnimationKey(frame: frame, floatValue: value)
            try addKey(newKey)
        }
    }
    
    public func setColor(_ color: CGColor, at frame: UInt) throws {
        if let key = getKey(at: frame) {
            key.set(colorValue: color)
        }
        else {
            let newKey = AssetAnimationKey(frame: frame, colorValue: color)
            try addKey(newKey)
        }
    }
    
    public func setString(_ value: String, at frame: UInt) throws {
        if let key = getKey(at: frame) {
            key.set(stringValue: value)
        }
        else {
            let newKey = AssetAnimationKey(frame: frame, stringValue: value)
            try addKey(newKey)
        }
    }
    
    private func addKey(_ key: AssetAnimationKey) throws {
        if let _ = getKey(at: key.frame) {
            throw AssetAnimationTrackError.duplicateKeyFrame
        }
        
        keys.append(key)
        keys.sort { key1, key2 in
            key1.frame < key2.frame
        }
    }
    
    public func toSKAction(with expectedDuration: TimeInterval, for elementInstance: TransformAssetElementInstance) -> SKAction? {
        guard
            let firstKey,
            let lastKey,
            firstKey.frame != lastKey.frame
        else {
            return nil
        }
        
        let firstKeyTime = firstKey.time
        if firstKeyTime >= expectedDuration {
            return nil
        }
        
        var sequence = [SKAction]()
        
        if firstKey.frame > 0 {
            sequence.append(SKAction.wait(forDuration: firstKeyTime))
        }
        
        var previousKeyTime = firstKeyTime
        for i in 1..<keys.count {
            let key = keys[i]
            let keyTime = key.time
            let previousKey = keys[i - 1]
            
            let duration = keyTime > expectedDuration ? (expectedDuration - previousKeyTime) : (keyTime - previousKeyTime)
            if let actions = elementInstance.buildSKActions(for: self, from: previousKey, to: key, duration: duration) {
                sequence.append(contentsOf: actions)
            }
            
            previousKeyTime = keyTime
        }
        
        var durationSum: TimeInterval = 0
        for action in sequence {
            durationSum += action.duration
        }
        if durationSum < expectedDuration {
            sequence.append(SKAction.wait(forDuration: expectedDuration - durationSum))
        }
        
        return SKAction.sequence(sequence)
    }
    
}
