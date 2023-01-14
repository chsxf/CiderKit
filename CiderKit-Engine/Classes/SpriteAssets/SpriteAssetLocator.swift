public struct SpriteAssetLocator : Codable, CustomStringConvertible, Equatable {
    
    public let databaseKey: String
    public let assetUUID: UUID
    
    public var description: String {
        return "\(databaseKey)/\(assetUUID)"
    }
    
    public var assetDescription: SpriteAssetDescription? {
        guard let database = Project.current?.spriteAssetDatabase(forId: databaseKey) else {
            return nil
        }
        return database[assetUUID]
    }
    
    public init(databaseKey: String, assetUUID: UUID) {
        self.databaseKey = databaseKey
        self.assetUUID = assetUUID
    }
    
    public init(from decoder: Decoder) throws {
        let dec = try decoder.singleValueContainer()
        let description = try dec.decode(String.self)
        let chunks = description.split(separator: "/", maxSplits: 1).map { String($0) }
        let uuid = UUID(uuidString: chunks[1])!
        self.init(databaseKey: chunks[0], assetUUID: uuid)
    }
    
    public static func == (lhs: SpriteAssetLocator, rhs: SpriteAssetLocator) -> Bool {
        return lhs.databaseKey == rhs.databaseKey && lhs.assetUUID == rhs.assetUUID
    }
    
    public func encode(to encoder: Encoder) throws {
        var enc = encoder.singleValueContainer()
        try enc.encode(description)
    }
    
}
