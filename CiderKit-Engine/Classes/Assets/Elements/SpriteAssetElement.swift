import CoreGraphics
import SpriteKit

extension AssetElementCodingKeys {
    
    static let volumeWorldOffset = Self.init(stringValue: "vo")!
    static let volumeWorldSize = Self.init(stringValue: "vs")!
    static let sprite = Self.init(stringValue: "s")!
    static let anchorPoint = Self.init(stringValue: "ap")!
    static let color = Self.init(stringValue: "cl")!
    static let colorBlend = Self.init(stringValue: "cb")!
    
}

extension AssetAnimationTrackType {
    
    public static let xVolumeWorldOffset = Self.init(name: "xVolumeWorldOffset", displayName: "Volume World Offset (X)", systemSymbolName: "arrow.up.left.and.arrow.down.right.square.fill")
    public static let yVolumeWorldOffset = Self.init(name: "yVolumeWorldOffset", displayName: "Volume World Offset (Y)", systemSymbolName: "arrow.down.left.and.arrow.up.right.square.fill")
    public static let zVolumeWorldOffset = Self.init(name: "zVolumeWorldOffset", displayName: "Volume World Offset (Z)", systemSymbolName: "arrow.up.and.down.square.fill")

    public static let xVolumeWorldSize = Self.init(name: "xVolumeWorldSize", displayName: "Volume World Size (X)", systemSymbolName: "arrow.up.left.and.arrow.down.right.square")
    public static let yVolumeWorldSize = Self.init(name: "yVolumeWorldSize", displayName: "Volume World Size (Y)", systemSymbolName: "arrow.down.left.and.arrow.up.right.square")
    public static let zVolumeWorldSize = Self.init(name: "zVolumeWorldSize", displayName: "Volume World Size (Z)", systemSymbolName: "arrow.up.and.down.square")

    public static let xAnchorPoint = Self.init(name: "xAnchorPoint", displayName: "Anchor Point (X)", systemSymbolName: "scope")
    public static let yAnchorPoint = Self.init(name: "yAnchorPoint", displayName: "Anchor Point (Y)", systemSymbolName: "scope")
    
}

public class SpriteAssetElement : TransformAssetElement {
    
    enum CGColorCodingKeys: String, CodingKey {
        case colorSpaceName = "csn"
        case components = "cmp"
    }
    
    public var volumeWorldOffset: WorldPosition
    public var volumeWorldSize: WorldPosition

    public var spriteLocator: SpriteLocator?
    public var anchorPoint: CGPoint
    
    public var color: CGColor
    public var colorBlend: Float
    
    public override var type: String { "sprite" }
    
    public override class var typeLabel: String { "Sprite Element" }
    
    public override var eligibleTrackTypes: [AssetAnimationTrackType] {
        var trackTypes = super.eligibleTrackTypes
        trackTypes.append(contentsOf: [.xVolumeWorldOffset, .yVolumeWorldOffset, .zVolumeWorldOffset, .xVolumeWorldSize, .yVolumeWorldSize, .zVolumeWorldSize, .sprite, .xAnchorPoint, .yAnchorPoint, .color, .colorBlendFactor])
        return trackTypes
    }
    
    public override var combinedTrackTypes: [AssetAnimationTrackType] {
        var combinedTrackTypes = super.combinedTrackTypes
        combinedTrackTypes.append(contentsOf: [.xVolumeWorldOffset, .yVolumeWorldOffset, .zVolumeWorldOffset, .xVolumeWorldSize, .yVolumeWorldSize, .zVolumeWorldSize, .xAnchorPoint, .yAnchorPoint ])
        return combinedTrackTypes
    }
    
    public required init(name: String) {
        volumeWorldOffset = WorldPosition()
        volumeWorldSize = WorldPosition(1, 1, 1)
        spriteLocator = nil
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        color = SKColor.white.cgColor
        colorBlend = 0
        
        super.init(name: name)
    }
    
    public override func encode(to container: inout KeyedEncodingContainer<AssetElementCodingKeys>) throws {
        try super.encode(to: &container)
        
        try container.encode(volumeWorldOffset, forKey: .volumeWorldOffset)
        try container.encode(volumeWorldSize, forKey: .volumeWorldSize)
        
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
        volumeWorldOffset = try container.decode(WorldPosition.self, forKey: .volumeWorldOffset)
        volumeWorldSize = try container.decode(WorldPosition.self, forKey: .volumeWorldSize)

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
            color = SKColor.white.cgColor
            colorBlend = 0
        }

        try super.init(from: container)
    }
    
    public override subscript(trackType: AssetAnimationTrackType) -> Any? {
        get {
            switch trackType {
            case .xVolumeWorldOffset:
                return volumeWorldOffset.x
            case .yVolumeWorldOffset:
                return volumeWorldOffset.y
            case .zVolumeWorldOffset:
                return volumeWorldOffset.z
            case .xVolumeWorldSize:
                return volumeWorldSize.x
            case .yVolumeWorldSize:
                return volumeWorldSize.y
            case .zVolumeWorldSize:
                return volumeWorldSize.z
            case .sprite:
                return spriteLocator?.description
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
                case .xVolumeWorldOffset:
                    volumeWorldOffset.x = value as! Float
                case .yVolumeWorldOffset:
                    volumeWorldOffset.y = value as! Float
                case .zVolumeWorldOffset:
                    volumeWorldOffset.z = value as! Float
                case .xVolumeWorldSize:
                    volumeWorldSize.x = value as! Float
                case .yVolumeWorldSize:
                    volumeWorldSize.y = value as! Float
                case .zVolumeWorldSize:
                    volumeWorldSize.z = value as! Float
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

    public override func instantiate() -> TransformAssetElementInstance {
        SpriteAssetElementInstance(element: self)
    }
    
}
