import SpriteKit

extension AssetElementCodingKeys {
    
    static let reference = Self.init(stringValue: "ref")!
    
}

public class ReferenceAssetElement : TransformAssetElement {
    
    private static let assetLocatorDescriptionKey = "asset-locator-description"
    
    public override var type: String { "reference" }
    
    public override class var typeLabel: String { "Reference Element" }
    
    public var assetLocator: AssetLocator?
    
    public required init(name: String) {
        super.init(name: name)
        
        assetLocator = nil
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AssetElementCodingKeys.self)
        try self.init(from: container)
    }
    
    public required init(from container: KeyedDecodingContainer<AssetElementCodingKeys>) throws {
        try super.init(from: container)
        
        assetLocator = try container.decodeIfPresent(AssetLocator.self, forKey: .reference)
    }
    
    public override func encode(to container: inout KeyedEncodingContainer<AssetElementCodingKeys>) throws {
        try super.encode(to: &container)
        
        if let assetLocator {
            try container.encode(assetLocator, forKey: .reference)
        }
    }
    
    public override func instantiate() -> TransformAssetElementInstance {
        ReferenceAssetElementInstance(element: self)
    }
}
