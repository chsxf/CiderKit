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

    public var uuid: UUID

    public var name: String
    public var visible: Bool
    public var worldOffset: WorldPosition
    public var horizontallyFlipped: Bool
    
    public var children: [SendableMutableRef<any AssetElement>]

    public var type: String { "transform" }
    public static var typeLabel: String { "Transform Element" }

    public subscript(trackType: AssetAnimationTrackType) -> Any? {
        get { get(baseTrackType: trackType) }
        set { set(baseTrackType: trackType, value: newValue) }
    }

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
    
    public init(from container: KeyedDecodingContainer<AssetElementCodingKeys>) throws {
        (uuid, name, visible, worldOffset, horizontallyFlipped, children) = try Self.decodeBaseProperties(from: container)
        setParentForChildren()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AssetElementCodingKeys.self)
        try encode(to: &container)
    }
    
    @MainActor
    public func instantiate() -> TransformAssetElementInstance {
        TransformAssetElementInstance(element: self)
    }
    
}
