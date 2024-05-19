public class AssetPlacement: Codable, Identifiable, ObservableObject, NamedObject {

    enum CodingKeys: String, CodingKey {
        case id
        case name = "n"
        case assetLocator = "al"
        case x
        case y
        case worldOffset = "wo"
        case horizontallyFlipped = "f"
        case interactive = "i"
    }
    
    public let id: UUID
    @Published public var name: String
    @Published public var assetLocator: AssetLocator
    public var x: Int
    public var y: Int
    @Published public var worldOffset: CGPoint
    @Published public var horizontallyFlipped: Bool
    @Published public var interactive: Bool
    
    public init(assetLocator: AssetLocator, horizontallyFlipped: Bool, atX x: Int = 0, y: Int = 0, worldOffset: CGPoint = CGPoint(), name: String = "") {
        id = UUID()
        self.name = name
        self.assetLocator = assetLocator
        self.x = x
        self.y = y
        self.worldOffset = worldOffset
        self.horizontallyFlipped = horizontallyFlipped
        interactive = false
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        assetLocator = try container.decode(AssetLocator.self, forKey: .assetLocator)
        x = try container.decode(Int.self, forKey: .x)
        y = try container.decode(Int.self, forKey: .y)
        worldOffset = try container.decode(CGPoint.self, forKey: .worldOffset)
        horizontallyFlipped = try container.decodeIfPresent(Bool.self, forKey: .horizontallyFlipped) ?? false
        interactive = try container.decodeIfPresent(Bool.self, forKey: .interactive) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(assetLocator, forKey: .assetLocator)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(worldOffset, forKey: .worldOffset)
        try container.encode(horizontallyFlipped, forKey: .horizontallyFlipped)
        try container.encode(interactive, forKey: .interactive)
    }
    
}
