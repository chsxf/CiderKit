public class SpriteAssetDatabase: Identifiable, Codable, CustomStringConvertible {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case isDefault = "isDefault"
        case version = "version"
        case assets = "spriteAssets"
    }
    
    public static let defaultDatabaseId = "_default"
    
    public let id: String
    public var isDefault: Bool = false
    public var version: String = "0.1"
    
    public var description: String { id }
    
    public var spriteAssets: [SpriteAssetDescription] = []
    
    public var sourceURL: URL? = nil
    
    public init(id: String) {
        self.id = id
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
        version = try container.decode(String.self, forKey: .version)
        
        spriteAssets = []
        var assetsContainer = try container.nestedUnkeyedContainer(forKey: .assets)
        while !assetsContainer.isAtEnd {
            spriteAssets.append(try assetsContainer.decode(SpriteAssetDescription.self))
        }
    }
    
    public subscript(uuid: UUID) -> SpriteAssetDescription? {
        for asset in spriteAssets {
            if asset.uuid == uuid {
                return asset
            }
        }
        return nil
    }
    
    public subscript(uuid: String) -> SpriteAssetDescription? {
        if let parsedUUID = UUID(uuidString: uuid) {
            return self[parsedUUID]
        }
        return nil
    }
    
    public class func idFromFilename(_ filename: String) -> String {
        let lowerCaseTrimmed = filename.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let invalidCharactersRE = try! NSRegularExpression(pattern: "[^a-z0-9-]")
        let onlyValidCharacters = invalidCharactersRE.stringByReplacingMatches(in: lowerCaseTrimmed, range: NSMakeRange(0, lowerCaseTrimmed.count), withTemplate: "-")
        
        let trimmed = onlyValidCharacters.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let successiveCaretsRE = try! NSRegularExpression(pattern: "-{2,}")
        
        let sanitiezd = successiveCaretsRE.stringByReplacingMatches(in: trimmed, range: NSMakeRange(0, trimmed.count), withTemplate: "-")
        return sanitiezd
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encode(version, forKey: .version)
        
        var assetsContainer = container.nestedUnkeyedContainer(forKey: .assets)
        for asset in spriteAssets {
            try assetsContainer.encode(asset)
        }
    }
    
}