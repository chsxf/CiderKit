import SpriteKit

extension AssetElementCodingKeys {
    
    static let uuid = Self.init(stringValue: "id")!
    static let name = Self.init(stringValue: "n")!
    static let type = Self.init(stringValue: "t")!
    static let visible = Self.init(stringValue: "v")!
    static let worldOffset = Self.init(stringValue: "o")!
    static let children = Self.init(stringValue: "c")!
    static let horizontallyFlipped = Self.init(stringValue: "f")!
    
}

extension AssetAnimationTrackType {
    
    public static let xWorldOffset = Self.init(name: "xWorldOffset", displayName: "X World Offset", systemSymbolName: "arrow.up.left.and.arrow.down.right")
    public static let yWorldOffset = Self.init(name: "yWorldOffset", displayName: "Y World Offset", systemSymbolName: "arrow.down.left.and.arrow.up.right")
    public static let zWorldOffset = Self.init(name: "zWorldOffset", displayName: "Z World Offset", systemSymbolName: "arrow.up.and.down")

}

public class TransformAssetElement : Hashable, Codable {
    
    public private(set) weak var parent: TransformAssetElement? = nil
    
    public var isRoot: Bool { parent == nil }
    
    public private(set) var uuid: UUID

    public var name: String
    public var visible: Bool
    public var worldOffset: WorldPosition
    public var horizontallyFlipped: Bool
    
    public private(set) var children: [TransformAssetElement]

    public var type: String { "transform" }
    
    public var absoluteWorldOffset: WorldPosition {
        var result = worldOffset
        if let parent {
            result += parent.absoluteWorldOffset
        }
        return result
    }
    
    public class var typeLabel: String { "Transform Element" }
    
    public var eligibleTrackTypes: [AssetAnimationTrackType] {
        [ .xWorldOffset, .yWorldOffset, .zWorldOffset, .visibility ]
    }
    
    public var combinedTrackTypes: [AssetAnimationTrackType] {
        [ .xWorldOffset, .yWorldOffset, .zWorldOffset ]
    }
    
    public required init(name: String) {
        uuid = UUID()
        self.name = name
        
        visible = true
        worldOffset = WorldPosition()
        horizontallyFlipped = false

        children = []
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AssetElementCodingKeys.self)
        try self.init(from: container)
    }
    
    public required init(from container: KeyedDecodingContainer<AssetElementCodingKeys>) throws {
        uuid = try container.decode(UUID.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        
        visible = (try container.decodeIfPresent(Bool.self, forKey: .visible)) ?? true
        worldOffset = try container.decode(WorldPosition.self, forKey: .worldOffset)
        horizontallyFlipped = (try container.decodeIfPresent(Bool.self, forKey: .horizontallyFlipped)) ?? false
        
        children = []
        if var childrenSubContainer = try? container.nestedUnkeyedContainer(forKey: .children) {
            while !childrenSubContainer.isAtEnd {
                let childContainer = try childrenSubContainer.nestedContainer(keyedBy: AssetElementCodingKeys.self)
                let childTypeName = try childContainer.decode(String.self, forKey: .type)
                let childType = try AssetElementTypeRegistry.get(named: childTypeName)
                let child = try childType.init(from: childContainer)
                children.append(child)
            }
        }
        
        setParentForChildren()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AssetElementCodingKeys.self)
        try encode(to: &container)
    }
    
    public func encode(to container: inout KeyedEncodingContainer<AssetElementCodingKeys>) throws {
        try container.encode(uuid, forKey: .uuid)
        
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        
        try container.encode(visible, forKey: .visible)
        try container.encode(worldOffset, forKey: .worldOffset)
        try container.encode(horizontallyFlipped, forKey: .horizontallyFlipped)

        if !children.isEmpty {
            var subContainer = container.nestedUnkeyedContainer(forKey: .children)
            for child in children {
                try subContainer.encode(child)
            }
        }
    }
    
    public func renewUUID() -> UUID {
        uuid = UUID()
        return uuid
    }

    private func setParentForChildren() {
        for child in children {
            child.parent = self
            child.setParentForChildren()
        }
    }
    
    public func addChild(_ child: TransformAssetElement) {
        children.append(child)
        child.parent = self
    }
    
    public func removeFromParent() {
        if let parent = parent {
            parent.children.removeAll { $0 === self }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    public static func == (lhs: TransformAssetElement, rhs: TransformAssetElement) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    public func getElement(uuid: UUID) -> TransformAssetElement? {
        if self.uuid == uuid {
            return self
        }
        else {
            for child in children {
                if let element = child.getElement(uuid: uuid) {
                    return element
                }
            }
        }
        return nil
    }
    
    public func getElementRelativeOrder(uuid: UUID) -> Int? {
        if self.uuid == uuid {
            return 0
        }
        else {
            for i in 0..<children.count {
                let child = children[i]
                if let order  = child.getElementRelativeOrder(uuid: uuid) {
                    return order + i + 1
                }
            }
        }
        return nil
    }
    
    public subscript(trackType: AssetAnimationTrackType) -> Any? {
        get {
            switch trackType {
            case .visibility:
                return visible
            case .xWorldOffset:
                return worldOffset.x
            case .yWorldOffset:
                return worldOffset.y
            case .zWorldOffset:
                return worldOffset.z
            default:
                return nil
            }
        }
        
        set(value) {
            if let value {
                switch trackType {
                case .visibility:
                    visible = value as! Bool
                case .xWorldOffset:
                    if value is CGFloat {
                        worldOffset.x = Float(value as! CGFloat)
                    }
                    else if value is Float {
                        worldOffset.x = value as! Float
                    }
                case .yWorldOffset:
                    if value is CGFloat {
                        worldOffset.y = Float(value as! CGFloat)
                    }
                    else if value is Float {
                        worldOffset.y = value as! Float
                    }
                case .zWorldOffset:
                    if value is CGFloat {
                        worldOffset.z = Float(value as! CGFloat)
                    }
                    else if value is Float {
                        worldOffset.z = value as! Float
                    }
                default:
                    break
                }
            }
        }
    }
    
    public func instantiate() -> TransformAssetElementInstance {
        TransformAssetElementInstance(element: self)
    }
    
}
