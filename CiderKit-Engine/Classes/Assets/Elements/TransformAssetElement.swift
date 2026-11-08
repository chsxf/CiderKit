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

public struct TransformAssetElement: AssetElement {

    public let parent: SendableMutableRef<any AssetElement?> = SendableMutableRef(nil)

    public var isRoot: Bool { parent.ref == nil }

    public var uuid: UUID

    public var name: String
    public var visible: Bool
    public var worldOffset: WorldPosition
    public var horizontallyFlipped: Bool
    
    public var children: [SendableMutableRef<any AssetElement>]

    public var type: String { "transform" }
    
    public static var typeLabel: String { "Transform Element" }

    public var eligibleTrackTypes: [AssetAnimationTrackType] {
        [ .xWorldOffset, .yWorldOffset, .zWorldOffset, .visibility ]
    }
    
    public var combinedTrackTypes: [AssetAnimationTrackType] {
        [ .xWorldOffset, .yWorldOffset, .zWorldOffset ]
    }
    
    public init(name: String) {
        uuid = UUID()
        self.name = name
        
        visible = true
        worldOffset = WorldPosition()
        horizontallyFlipped = false

        children = []
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AssetElementCodingKeys.self)
        try self.init(from: container)
    }
    
    public init(from container: KeyedDecodingContainer<AssetElementCodingKeys>) throws {
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
                let childRef = SendableMutableRef(child)
                children.append(childRef)
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
                try subContainer.encode(child.ref)
            }
        }
    }
    
    @MainActor
    public func instantiate() -> TransformAssetElementInstance {
        TransformAssetElementInstance(element: self)
    }
    
}
