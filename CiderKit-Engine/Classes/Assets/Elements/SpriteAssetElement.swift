import CoreGraphics
import SpriteKit

extension AssetElementCodingKeys {
    
    static let volumeOffset = Self.init(stringValue: "vo")!
    static let volumeSize = Self.init(stringValue: "vs")!
    static let sprite = Self.init(stringValue: "s")!
    static let anchorPoint = Self.init(stringValue: "ap")!
    static let color = Self.init(stringValue: "cl")!
    static let colorBlend = Self.init(stringValue: "cb")!
    
}

extension AssetAnimationTrackType {
    
    public static let xVolumeOffset = Self.init(name: "xVolumeOffset", displayName: "Volume Offset (X)", systemSymbolName: "arrow.up.left.and.arrow.down.right.square.fill")
    public static let yVolumeOffset = Self.init(name: "yVolumeOffset", displayName: "Volume Offset (Y)", systemSymbolName: "arrow.down.left.and.arrow.up.right.square.fill")
    public static let zVolumeOffset = Self.init(name: "zVolumeOffset", displayName: "Volume Offset (Z)", systemSymbolName: "arrow.up.and.down.square.fill")
    
    public static let xVolumeSize = Self.init(name: "xVolumeSize", displayName: "Volume Size (X)", systemSymbolName: "arrow.up.left.and.arrow.down.right.square")
    public static let yVolumeSize = Self.init(name: "yVolumeSize", displayName: "Volume Size (Y)", systemSymbolName: "arrow.down.left.and.arrow.up.right.square")
    public static let zVolumeSize = Self.init(name: "zVolumeSize", displayName: "Volume Size (Z)", systemSymbolName: "arrow.up.and.down.square")
    
    public static let xAnchorPoint = Self.init(name: "xAnchorPoint", displayName: "Anchor Point (X)", systemSymbolName: "scope")
    public static let yAnchorPoint = Self.init(name: "yAnchorPoint", displayName: "Anchor Point (Y)", systemSymbolName: "scope")
    
}

public class SpriteAssetElement : TransformAssetElement {
    
    enum CGColorCodingKeys: String, CodingKey {
        case colorSpaceName = "csn"
        case components = "cmp"
    }
    
    public var volumeOffset: SIMD3<Float>
    public var volumeSize: SIMD3<Float>
    
    public var spriteLocator: SpriteLocator?
    public var anchorPoint: CGPoint
    
    public var color: CGColor
    public var colorBlend: Float
    
    public override var type: String { "sprite" }
    
    public override class var typeLabel: String { "Sprite Element" }
    
    public override var eligibleTrackTypes: [AssetAnimationTrackType] {
        var trackTypes = super.eligibleTrackTypes
        trackTypes.append(contentsOf: [.xVolumeOffset, .yVolumeOffset, .zVolumeOffset, .xVolumeSize, .yVolumeSize, .zVolumeSize, .sprite, .xAnchorPoint, .yAnchorPoint, .color, .colorBlendFactor])
        return trackTypes
    }
    
    public override var combinedTrackTypes: [AssetAnimationTrackType] {
        var combinedTrackTypes = super.combinedTrackTypes
        combinedTrackTypes.append(contentsOf: [.xVolumeOffset, .yVolumeOffset, .zVolumeOffset, .xVolumeSize, .yVolumeSize, .zVolumeSize, .xAnchorPoint, .yAnchorPoint ])
        return combinedTrackTypes
    }
    
    public required init(name: String) {
        volumeOffset = SIMD3()
        volumeSize = SIMD3(1, 1, 1)
        spriteLocator = nil
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        color = CGColor.white
        colorBlend = 0
        
        super.init(name: name)
    }
    
    public override func encode(to container: inout KeyedEncodingContainer<AssetElementCodingKeys>) throws {
        try super.encode(to: &container)
        
        try container.encode(volumeOffset, forKey: .volumeOffset)
        try container.encode(volumeSize, forKey: .volumeSize)
        
        if let spriteLocator {
            try container.encode(spriteLocator, forKey: .sprite)
        }
        try container.encode(anchorPoint, forKey: .anchorPoint)
        
        let colorSpaceName = color.colorSpace!.name! as String
        var subContainer = container.nestedContainer(keyedBy: CGColorCodingKeys.self, forKey: .color)
        try subContainer.encode(colorSpaceName, forKey: .colorSpaceName)
        var componentsContainer = subContainer.nestedUnkeyedContainer(forKey: .components)
        for component in color.components! {
            try componentsContainer.encode(component)
        }
        
        try container.encode(colorBlend, forKey: .colorBlend)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AssetElementCodingKeys.self)
        try self.init(from: container)
    }
    
    public required init(from container: KeyedDecodingContainer<AssetElementCodingKeys>) throws {
        volumeOffset = try container.decode(SIMD3<Float>.self, forKey: .volumeOffset)
        volumeSize = try container.decode(SIMD3<Float>.self, forKey: .volumeSize)
        
        spriteLocator = try container.decodeIfPresent(SpriteLocator.self, forKey: .sprite)
        anchorPoint = try container.decode(CGPoint.self, forKey: .anchorPoint)
        
        if let colorSubContainer = try? container.nestedContainer(keyedBy: CGColorCodingKeys.self, forKey: .color) {
            let colorSpaceName = try colorSubContainer.decode(String.self, forKey: .colorSpaceName)
            var componentsSubContainer = try colorSubContainer.nestedUnkeyedContainer(forKey: .components)
            var components = [CGFloat]()
            while !componentsSubContainer.isAtEnd {
                components.append(try componentsSubContainer.decode(CGFloat.self))
            }
            color = CGColor(colorSpace: CGColorSpace(name: colorSpaceName as CFString)!, components: components)!
            
            colorBlend = try container.decode(Float.self, forKey: .colorBlend)
        }
        else {
            color = CGColor.white
            colorBlend = 0
        }

        try super.init(from: container)
    }
    
    public override subscript(trackType: AssetAnimationTrackType) -> Any? {
        get {
            switch trackType {
            case .xVolumeOffset:
                return volumeOffset.x
            case .yVolumeOffset:
                return volumeOffset.y
            case .zVolumeOffset:
                return volumeOffset.z
            case .xVolumeSize:
                return volumeSize.x
            case .yVolumeSize:
                return volumeSize.y
            case .zVolumeSize:
                return volumeSize.z
            case .sprite:
                return spriteLocator
            case .xAnchorPoint:
                return anchorPoint.x
            case .yAnchorPoint:
                return anchorPoint.y
            case .color:
                return color
            case .colorBlendFactor:
                return colorBlend
            default:
                return super[trackType]
            }
        }
        
        set(value) {
            if let value {
                switch trackType {
                case .xVolumeOffset:
                    volumeOffset.x = value as! Float
                case .yVolumeOffset:
                    volumeOffset.y = value as! Float
                case .zVolumeOffset:
                    volumeOffset.z = value as! Float
                case .xVolumeSize:
                    volumeSize.x = value as! Float
                case .yVolumeSize:
                    volumeSize.y = value as! Float
                case .zVolumeSize:
                    volumeSize.z = value as! Float
                case .sprite:
                    if value is SpriteLocator {
                        spriteLocator = value as? SpriteLocator
                    }
                    else if value is String {
                        spriteLocator = SpriteLocator(description: value as! String)
                    }
                case .xAnchorPoint:
                    if value is CGFloat {
                        anchorPoint.x = value as! CGFloat
                    }
                    else if value is Float {
                        anchorPoint.x = CGFloat(value as! Float)
                    }
                case .yAnchorPoint:
                    if value is CGFloat {
                        anchorPoint.y = value as! CGFloat
                    }
                    else if value is Float {
                        anchorPoint.y = CGFloat(value as! Float)
                    }
                case .color:
                    color = value as! CGColor
                case .colorBlendFactor:
                    colorBlend = value as! Float
                default:
                    super[trackType] = value
                }
            }
        }
    }
    
    private func updateSprite(_ spriteNode: SKSpriteNode, spriteLocator: SpriteLocator?) {
        if let spriteLocator {
            let texture = Atlases[spriteLocator]!
            spriteNode.texture = texture
            spriteNode.size = texture.size()
            
            let atlas = Atlases[spriteLocator.atlasKey]!
            spriteNode.shader = CiderKitEngine.instantianteUberShader(for: atlas)
        }
        else {
            spriteNode.texture = CiderKitEngine.clearTexture
            spriteNode.shader = nil
        }
    }
    
    public override func buildSKActions(for track: AssetAnimationTrack, from key1: AssetAnimationKey, to key2: AssetAnimationKey, duration: TimeInterval) -> [SKAction]? {
        let adjustedDuration = key1 === track.firstKey ? duration : (duration - AssetAnimationTrack.frameTime)
        
        switch track.type {
        case .color:
            let endColor = key2.colorValue!
            if key1.maintainValue {
                return [
                    SKAction.wait(forDuration: adjustedDuration),
                    SKAction.customAction(withDuration: AssetAnimationTrack.frameTime, actionBlock: { node, _ in
                        if let sprite = node as? SKSpriteNode {
                            sprite.color = SKColorFromCGColor(endColor)
                        }
                    })
                ]
            }
            else {
                let startColor = key1.colorValue!
                let action = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                    if let sprite = node as? SKSpriteNode {
                        let ratio = Float(elapsedTime / duration)
                        sprite.color = SKColorFromCGColor(CGColor.interpolateRGB(from: startColor, to: endColor, t: ratio)!)
                    }
                }
                action.setupTimingFunction(key1.timingInterpolation)
                return [ action ]
            }

        case .colorBlendFactor:
            if key1.maintainValue {
                return [
                    SKAction.wait(forDuration: adjustedDuration),
                    SKAction.customAction(withDuration: AssetAnimationTrack.frameTime, actionBlock: { node, _ in
                        if let sprite = node as? SKSpriteNode {
                            sprite.colorBlendFactor = CGFloat(key2.floatValue!)
                        }
                    })
                ]
            }
            else {
                let action = SKAction.colorize(withColorBlendFactor: CGFloat(key2.floatValue!), duration: duration)
                action.setupTimingFunction(key1.timingInterpolation)
                return [ action ]
            }

        case .sprite:
            var sequence = [SKAction]()
            sequence.append(SKAction.wait(forDuration: adjustedDuration))
            if let spriteLocator = SpriteLocator(description: key2.stringValue!) {
                sequence.append(SKAction.customAction(withDuration: AssetAnimationTrack.frameTime, actionBlock: { node, _ in
                    if let sprite = node as? SKSpriteNode {
                        node.alpha = 1
                        sprite.texture = Atlases[spriteLocator]!
                    }
                }))
            }
            else {
                sequence.append(SKAction.customAction(withDuration: AssetAnimationTrack.frameTime, actionBlock: { node, _ in
                    if let _ = node as? SKSpriteNode {
                        node.alpha = 0
                    }
                }))
            }
            return sequence
            
        default:
            return nil
        }
    }
    
    public override func buildSKActions(with combinedTracks: [AssetAnimationTrackType : AssetAnimationTrack], expectedDuration: TimeInterval) -> [SKAction] {
        var actions = super.buildSKActions(with: combinedTracks, expectedDuration: expectedDuration)
        
        let xAnchorPoint = combinedTracks[.xAnchorPoint]
        let yAnchorPoint = combinedTracks[.yAnchorPoint]
        if xAnchorPoint != nil || yAnchorPoint != nil {
            actions.append(SKAction.customAction(withDuration: expectedDuration) { node, elapsedTime in
                guard let spriteNode = node as? SKSpriteNode else { return }
                
                let frame = Int((elapsedTime / AssetAnimationTrack.frameTime).rounded(.towardZero))
                
                let x = (xAnchorPoint?.getValue(at: frame) ?? Float(self.anchorPoint.x)) as! Float
                let y = (yAnchorPoint?.getValue(at: frame) ?? Float(self.anchorPoint.y)) as! Float
                
                spriteNode.anchorPoint = CGPoint(x: CGFloat(x), y: CGFloat(y))
            })
        }

        let xVolumeOffset = combinedTracks[.xVolumeOffset]
        let yVolumeOffset = combinedTracks[.yVolumeOffset]
        let zVolumeOffset = combinedTracks[.zVolumeOffset]
        let xVolumeSize = combinedTracks[.xVolumeSize]
        let yVolumeSize = combinedTracks[.yVolumeSize]
        let zVolumeSize = combinedTracks[.zVolumeSize]
        if xVolumeOffset != nil || yVolumeOffset != nil || zVolumeOffset != nil || xVolumeSize != nil || yVolumeSize != nil || zVolumeSize != nil {
            actions.append(SKAction.customAction(withDuration: expectedDuration) { node, elapsedTime in
                guard let spriteNode = node as? SKSpriteNode else { return }
                
                let frame = Int((elapsedTime / AssetAnimationTrack.frameTime).rounded(.towardZero))
                
                let volumeOffset = SIMD3(
                    (xVolumeOffset?.getValue(at: frame) ?? self.volumeOffset.x) as! Float,
                    (yVolumeOffset?.getValue(at: frame) ?? self.volumeOffset.y) as! Float,
                    (zVolumeOffset?.getValue(at: frame) ?? self.volumeOffset.z) as! Float
                )
                
                let volumeSize = SIMD3(
                    (xVolumeSize?.getValue(at: frame) ?? self.volumeSize.x) as! Float,
                    (yVolumeSize?.getValue(at: frame) ?? self.volumeSize.y) as! Float,
                    ((zVolumeSize?.getValue(at: frame) ?? self.volumeSize.z) as! Float) * 0.25
                )
                
                spriteNode.attributeValues = [
                    CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: self.absoluteOffset + volumeOffset),
                    CiderKitEngine.ShaderAttributeName.size.rawValue: SKAttributeValue(vectorFloat3: volumeSize)
                ]
            })
        }
        
        return actions
    }
    
    public override func instantiate() -> TransformAssetElementInstance {
        SpriteAssetElementInstance(element: self)
    }
    
}
