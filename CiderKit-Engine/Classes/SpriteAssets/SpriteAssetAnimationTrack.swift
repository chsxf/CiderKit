import SpriteKit

public enum SpriteAssetAnimationTrackError: Error {
    case invalidValueType
    case invalidFrame
    case duplicateKeyFrame
}

public class SpriteAssetAnimationTrack: Codable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case keys
    }

    static let frameTime: TimeInterval = 1.0/60.0
    
    let type: SpriteAssetAnimationTrackType
    
    private var keys: [SpriteAssetAnimationKey]
    
    public var hasAnyKey: Bool { !keys.isEmpty }
    
    public var firstKey: SpriteAssetAnimationKey? { keys.first }
    public var lastKey: SpriteAssetAnimationKey? { keys.last }
    
    public var duration: TimeInterval {
        guard let lastKey else { return -1 }
        return Self.frameTime * TimeInterval(lastKey.frame + 1)
    }
    
    public init(type: SpriteAssetAnimationTrackType) {
        self.type = type
        keys = []
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = SpriteAssetAnimationTrackType(rawValue: try container.decode(String.self, forKey: .type))!
        
        keys = []
        var keyContainer = try container.nestedUnkeyedContainer(forKey: .keys)
        while !keyContainer.isAtEnd {
            keys.append(try keyContainer.decode(SpriteAssetAnimationKey.self))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type.rawValue, forKey: .type)
        var keyContainer = container.nestedUnkeyedContainer(forKey: .keys)
        for key in keys {
            try keyContainer.encode(key)
        }
    }
    
    public func getValue(at frame: Int, for element: SpriteAssetElement? = nil) -> Any? {
        if !keys.isEmpty {
            if let key = getKey(at: frame) {
                return SpriteAssetAnimationKey.getInterpolatedValue(for: type, at: frame, from: key, to: nil)
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
                return SpriteAssetAnimationKey.getInterpolatedValue(for: type, at: frame, from: nil, to: keys.first)
            }
            else if selectedKeyIndex == keys.count {
                return SpriteAssetAnimationKey.getInterpolatedValue(for: type, at: frame, from: keys.last, to: nil)
            }
            else {
                return SpriteAssetAnimationKey.getInterpolatedValue(for: type, at: frame, from: keys[selectedKeyIndex], to: keys[selectedKeyIndex + 1])
            }
        }
        
        return element?[type]
    }
    
    public func hasKey(at frame: Int) -> Bool { getKey(at: frame) != nil }
    
    public func getKey(at frame: Int) -> SpriteAssetAnimationKey? {
        keys.first(where: { $0.frame == frame })
    }
    
    public func getNextKey(from frame: Int) -> SpriteAssetAnimationKey? {
        keys.first(where: { $0.frame > frame })
    }
    
    public func getPrevKey(from frame: Int) -> SpriteAssetAnimationKey? {
        keys.last(where: { $0.frame < frame })
    }
    
    public func removeKey(at frame: Int) {
        keys.removeAll(where: { $0.frame == frame })
    }
    
    public func setValue(_ value: Any, at frame: Int) throws {
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
            throw SpriteAssetAnimationTrackError.invalidValueType
        }
    }
    
    public func setBool(_ value: Bool, at frame: Int) throws {
        if type != .visibility {
            throw SpriteAssetAnimationTrackError.invalidValueType
        }
        
        if frame < 0 {
            throw SpriteAssetAnimationTrackError.invalidFrame
        }
        
        if let key = getKey(at: frame) {
            key.boolValue = value
        }
        else {
            let newKey = SpriteAssetAnimationKey(frame: frame)
            newKey.boolValue = value
            try addKey(newKey)
        }
    }
    
    public func setFloat(_ value: Float, at frame: Int) throws {
        switch type {
        case .xOffset, .yOffset, .rotation, .xScale, .yScale, .colorBlendFactor:
            break
            
        default:
            throw SpriteAssetAnimationTrackError.invalidValueType
        }
        
        if frame < 0 {
            throw SpriteAssetAnimationTrackError.invalidFrame
        }
        
        if let key = getKey(at: frame) {
            key.floatValue = value
        }
        else {
            let newKey = SpriteAssetAnimationKey(frame: frame)
            newKey.floatValue = value
            try addKey(newKey)
        }
    }
    
    public func setColor(_ color: CGColor, at frame: Int) throws {
        if type != .color {
            throw SpriteAssetAnimationTrackError.invalidValueType
        }
        
        if frame < 0 {
            throw SpriteAssetAnimationTrackError.invalidFrame
        }
        
        if let key = getKey(at: frame) {
            key.colorValue = color
        }
        else {
            let newKey = SpriteAssetAnimationKey(frame: frame)
            newKey.colorValue = color
            try addKey(newKey)
        }
    }
    
    public func setString(_ value: String, at frame: Int) throws {
        if type != .sprite {
            throw SpriteAssetAnimationTrackError.invalidValueType
        }
        
        if frame < 0 {
            throw SpriteAssetAnimationTrackError.invalidFrame
        }
        
        if let key = getKey(at: frame) {
            key.stringValue = value
        }
        else {
            let newKey = SpriteAssetAnimationKey(frame: frame)
            newKey.stringValue = value
            try addKey(newKey)
        }
    }
    
    private func addKey(_ key: SpriteAssetAnimationKey) throws {
        if let _ = getKey(at: key.frame) {
            throw SpriteAssetAnimationTrackError.duplicateKeyFrame
        }
        
        keys.append(key)
        keys.sort { key1, key2 in
            key1.frame < key2.frame
        }
    }
    
    private func setupSKActionTimingFunction(_ skAction: SKAction, with timingMode: SKActionTimingMode) {
        skAction.timingMode = .linear
        switch timingMode {
        case .easeIn:
            skAction.timingFunction = SpriteAssetAnimationKey.easeInInterpolationFunction(time:)
        case .easeOut:
            skAction.timingFunction = SpriteAssetAnimationKey.easeOutInterpolationFunction(time:)
        case .easeInEaseOut:
            skAction.timingFunction = SpriteAssetAnimationKey.easeInEaseOutInterpolationFunction(time:)
        default:
            break
        }
    }
    
    public func toSKAction(with expectedDuration: TimeInterval) -> SKAction? {
        guard
            let firstKey,
            let lastKey,
            firstKey.frame != lastKey.frame
        else {
            return nil
        }
        
        var sequence = [SKAction]()
        
        if firstKey.frame > 0 {
            sequence.append(SKAction.wait(forDuration: Self.frameTime * Double(firstKey.frame)))
        }
        
        for i in 1..<keys.count {
            let key = keys[i]
            let previousKey = keys[i - 1]
            let frameDiff = key.frame - previousKey.frame
            let duration = Self.frameTime * Double(frameDiff)
            let adjustedDuration = previousKey === firstKey ? duration : (duration - Self.frameTime)
            
            var action: SKAction? = nil
            
            switch type {
            case .visibility:
                sequence.append(SKAction.wait(forDuration: duration))
                sequence.append(key.boolValue! ? SKAction.unhide() : SKAction.hide())
                
            case .xOffset:
                if previousKey.maintainValue {
                    sequence.append(SKAction.wait(forDuration: adjustedDuration))
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        node.position = CGPoint(x: CGFloat(key.floatValue!), y: node.position.y)
                    }))
                }
                else {
                    let diff = key.floatValue! - previousKey.floatValue!
                    action = SKAction.moveBy(x: CGFloat(diff), y: 0, duration: duration)
                }
                
            case .yOffset:
                if previousKey.maintainValue {
                    sequence.append(SKAction.wait(forDuration: adjustedDuration))
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        node.position = CGPoint(x: node.position.x, y: CGFloat(key.floatValue!))
                    }))
                }
                else {
                    let diff = key.floatValue! - previousKey.floatValue!
                    action = SKAction.moveBy(x: 0, y: CGFloat(diff), duration: duration)
                }

            case .rotation:
                if previousKey.maintainValue {
                    sequence.append(SKAction.wait(forDuration: adjustedDuration))
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        node.zRotation = CGFloat(key.floatValue!)
                    }))
                }
                else {
                    action = SKAction.rotate(toAngle: CGFloat(key.floatValue!), duration: duration)
                }
                
            case .xScale:
                if previousKey.maintainValue {
                    sequence.append(SKAction.wait(forDuration: adjustedDuration))
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        node.xScale = CGFloat(key.floatValue!)
                    }))
                }
                else {
                    action = SKAction.scaleX(to: CGFloat(key.floatValue!), duration: duration)
                }
                
            case .yScale:
                if previousKey.maintainValue {
                    sequence.append(SKAction.wait(forDuration: adjustedDuration))
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        node.yScale = CGFloat(key.floatValue!)
                    }))
                }
                else {
                    action = SKAction.scaleY(to: CGFloat(key.floatValue!), duration: duration)
                }
                
            case .color:
                let endColor = key.colorValue!
                if previousKey.maintainValue {
                    sequence.append(SKAction.wait(forDuration: adjustedDuration))
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        if let sprite = node as? SKSpriteNode {
                            sprite.color = SKColorFromCGColor(endColor)
                        }
                    }))
                }
                else {
                    let startColor = previousKey.colorValue!
                    action = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                        if let sprite = node as? SKSpriteNode {
                            let ratio = Float(elapsedTime / duration)
                            sprite.color = SKColorFromCGColor(CGColor.interpolateRGB(from: startColor, to: endColor, t: ratio)!)
                        }
                    }
                }
                
            case .colorBlendFactor:
                if previousKey.maintainValue {
                    sequence.append(SKAction.wait(forDuration: adjustedDuration))
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        if let sprite = node as? SKSpriteNode {
                            sprite.colorBlendFactor = CGFloat(key.floatValue!)
                        }
                    }))
                }
                else {
                    action = SKAction.colorize(withColorBlendFactor: CGFloat(key.floatValue!), duration: duration)
                }
                
            case .sprite:
                sequence.append(SKAction.wait(forDuration: adjustedDuration))
                if let spriteLocator = SpriteLocator(description: key.stringValue!) {
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        if let sprite = node as? SKSpriteNode {
                            node.alpha = 1
                            sprite.texture = Atlases[spriteLocator]!
                        }
                    }))
                }
                else {
                    sequence.append(SKAction.customAction(withDuration: Self.frameTime, actionBlock: { node, _ in
                        if let _ = node as? SKSpriteNode {
                            node.alpha = 0
                        }
                    }))
                }
            }
            
            if let action {
                setupSKActionTimingFunction(action, with: previousKey.timingInterpolation)
                sequence.append(action)
            }
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
