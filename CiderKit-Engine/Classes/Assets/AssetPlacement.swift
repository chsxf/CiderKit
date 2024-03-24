public class AssetPlacement: Codable, Identifiable, ObservableObject {
    
    enum CodingKeys: String, CodingKey {
        case id
        case assetLocator = "al"
        case x
        case y
        case worldOffset = "wo"
        case horizontallyFlipped = "f"
    }
    
    public let id: UUID
    @Published public var assetLocator: AssetLocator
    public var x: Int
    public var y: Int
    @Published public var worldOffset: CGPoint
    public var horizontallyFlipped: Bool
    
    public init(assetLocator: AssetLocator, horizontallyFlipped: Bool, atX x: Int = 0, y: Int = 0, worldOffset: CGPoint = CGPoint()) {
        id = UUID()
        self.assetLocator = assetLocator
        self.x = x
        self.y = y
        self.worldOffset = worldOffset
        self.horizontallyFlipped = horizontallyFlipped
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        assetLocator = try container.decode(AssetLocator.self, forKey: .assetLocator)
        x = try container.decode(Int.self, forKey: .x)
        y = try container.decode(Int.self, forKey: .y)
        worldOffset = try container.decode(CGPoint.self, forKey: .worldOffset)
        horizontallyFlipped = try container.decodeIfPresent(Bool.self, forKey: .horizontallyFlipped) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(assetLocator, forKey: .assetLocator)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(worldOffset, forKey: .worldOffset)
        try container.encode(horizontallyFlipped, forKey: .horizontallyFlipped)
    }
    
}
