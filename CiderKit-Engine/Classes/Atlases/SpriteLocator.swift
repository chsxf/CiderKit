public struct SpriteLocator: Codable, CustomStringConvertible, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case atlas = "a"
        case atlasVariant = "v"
        case sprite = "s"
    }
    
    public let atlasKey: String
    public let atlasVariantKey: String?
    public let spriteName: String
    
    public var description: String {
        if let atlasVariantKey = atlasVariantKey {
            return "\(atlasKey)~\(atlasVariantKey)/\(spriteName)"
        }
        return "\(atlasKey)/\(spriteName)"
    }
    
    public init(key: String, sprite: String, variantKey: String? = nil) {
        atlasKey = key
        atlasVariantKey = variantKey
        spriteName = sprite
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        atlasKey = try container.decode(String.self, forKey: .atlas)
        atlasVariantKey = try? container.decode(String.self, forKey: .atlasVariant)
        spriteName = try container.decode(String.self, forKey: .sprite)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(atlasKey, forKey: .atlas)
        if let atlasVariantKey = atlasVariantKey {
            try container.encode(atlasVariantKey, forKey: .atlasVariant)
        }
        try container.encode(spriteName, forKey: .sprite)
    }
    
    public static func == (lhs: SpriteLocator, rhs: SpriteLocator) -> Bool {
        return lhs.atlasKey == rhs.atlasKey && lhs.atlasVariantKey == rhs.atlasVariantKey && lhs.spriteName == rhs.spriteName
    }
    
}
