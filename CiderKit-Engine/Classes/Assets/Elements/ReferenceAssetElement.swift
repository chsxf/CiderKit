import SpriteKit

extension AssetElementCodingKeys {
    
    static let reference = Self.init(stringValue: "ref")!
    static let animationName = Self.init(stringValue: "an")!
    
}

public struct ReferenceAssetElement: AssetElement {

    private static let assetLocatorDescriptionKey = "asset-locator-description"

    public let parent: SendableMutableRef<any AssetElement?> = SendableMutableRef(nil)

    public var uuid: UUID

    public var name: String
    public var visible: Bool
    public var worldOffset: WorldPosition
    public var horizontallyFlipped: Bool

    public var children: [SendableMutableRef<any AssetElement>]

    public var type: String { "reference" }
    public static var typeLabel: String { "Reference Element" }

    public var assetLocator: AssetLocator?
    
    public var animationName: String?
    
    public init(name: String) {
        uuid = UUID()
        self.name = name

        visible = true
        worldOffset = WorldPosition()
        horizontallyFlipped = false

        children = []

        assetLocator = nil
        animationName = nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AssetElementCodingKeys.self)
        try self.init(from: container)
    }
    
    public init(from container: KeyedDecodingContainer<AssetElementCodingKeys>) throws {
        assetLocator = try container.decodeIfPresent(AssetLocator.self, forKey: .reference)
        animationName = try container.decodeIfPresent(String.self, forKey: .animationName)

        (uuid, name, visible, worldOffset, horizontallyFlipped, children) = try Self.decodeBaseProperties(from: container)
        setParentForChildren()
    }
    
    public func encode(to container: inout KeyedEncodingContainer<AssetElementCodingKeys>) throws {
        try (self as (any AssetElement)).encode(to: &container)

        if let assetLocator {
            try container.encode(assetLocator, forKey: .reference)
        }
        
        if let animationName {
            try container.encode(animationName, forKey: .animationName)
        }
    }
    
    public func instantiate() -> TransformAssetElementInstance {
        ReferenceAssetElementInstance(element: self)
    }
}
