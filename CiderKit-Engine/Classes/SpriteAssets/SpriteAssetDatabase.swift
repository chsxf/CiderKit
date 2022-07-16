public class SpriteAssetDatabase: Identifiable, Codable {
    
    public let id: String
    public var isDefault: Bool = false
    public var version: String = "0.1"
    
    public var spriteAssets: [SpriteAssetDescription] = []
    
    public subscript(uuid: UUID) -> SpriteAssetDescription? {
        for asset in spriteAssets {
            if asset.id == uuid {
                return asset
            }
        }
        return nil
    }
    
}
