public struct SpriteAssetDescription: Identifiable, Codable {
    
    public var id: UUID = UUID()
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
    
}
