public class SpriteAssetDatabase: Identifiable, Codable {
    
    public static let defaultDatabaseId = "_default"
    
    public let id: String
    public var isDefault: Bool = false
    public var version: String = "0.1"
    
    public var spriteAssets: [SpriteAssetDescription] = []
    
    public init(id: String) {
        self.id = id
    }
    
    public subscript(uuid: UUID) -> SpriteAssetDescription? {
        for asset in spriteAssets {
            if asset.id == uuid {
                return asset
            }
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
    
}
