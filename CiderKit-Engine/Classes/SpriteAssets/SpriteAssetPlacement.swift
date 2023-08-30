public class SpriteAssetPlacement: Codable, Identifiable, ObservableObject {
    
    enum CodingKeys: String, CodingKey {
        case id
        case spriteAssetLocator = "sal"
        case x
        case y
        case worldOffset = "wo"
    }
    
    public let id: UUID
    @Published public var spriteAssetLocator: SpriteAssetLocator
    public var x: Int
    public var y: Int
    @Published public var worldOffset: CGPoint
    
    public init(spriteAssetLocator: SpriteAssetLocator, atX x: Int, y: Int, worldOffset: CGPoint) {
        id = UUID()
        self.spriteAssetLocator = spriteAssetLocator
        self.x = x
        self.y = y
        self.worldOffset = worldOffset
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        spriteAssetLocator = try container.decode(SpriteAssetLocator.self, forKey: .spriteAssetLocator)
        x = try container.decode(Int.self, forKey: .x)
        y = try container.decode(Int.self, forKey: .y)
        worldOffset = try container.decode(CGPoint.self, forKey: .worldOffset)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(spriteAssetLocator, forKey: .spriteAssetLocator)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(worldOffset, forKey: .worldOffset)
    }
    
}
