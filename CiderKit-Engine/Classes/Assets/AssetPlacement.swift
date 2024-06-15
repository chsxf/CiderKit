public final class AssetPlacement: Codable, Identifiable, ObservableObject, NamedObject {

    enum CodingKeys: String, CodingKey {
        case version = "v"
        case id
        case name = "n"
        case assetLocator = "al"
        case position = "p"
        case x
        case y
        case worldOffset = "wo"
        case horizontallyFlipped = "f"
        case interactive = "i"
    }
    
    private static let WITH_MAP_POSITION_VERSION = 2

    private static let VERSION = AssetPlacement.WITH_MAP_POSITION_VERSION

    public let version: Int
    public let id: UUID
    @Published public var name: String
    @Published public var assetLocator: AssetLocator
    @Published public var position: MapPosition
    @Published public var horizontallyFlipped: Bool
    @Published public var interactive: Bool
    
    public init(assetLocator: AssetLocator, horizontallyFlipped: Bool, position: MapPosition = MapPosition(), name: String = "") {
        id = UUID()
        self.version = Self.VERSION
        self.name = name
        self.assetLocator = assetLocator
        self.position = position
        self.horizontallyFlipped = horizontallyFlipped
        interactive = false
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        assetLocator = try container.decode(AssetLocator.self, forKey: .assetLocator)
        if version < Self.WITH_MAP_POSITION_VERSION {
            let x = try container.decode(Int.self, forKey: .x)
            let y = try container.decode(Int.self, forKey: .y)
            let worldOffset = try container.decode(CGPoint.self, forKey: .worldOffset)
            let simdWorldOffset = WorldPosition(Float(worldOffset.x), Float(worldOffset.y), 0)
            position = MapPosition(x: x, y: y, worldOffset: simdWorldOffset)
        }
        else {
            position = try container.decode(MapPosition.self, forKey: .position)
        }
        horizontallyFlipped = try container.decodeIfPresent(Bool.self, forKey: .horizontallyFlipped) ?? false
        interactive = try container.decodeIfPresent(Bool.self, forKey: .interactive) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(assetLocator, forKey: .assetLocator)
        try container.encode(position, forKey: .position)
        try container.encode(horizontallyFlipped, forKey: .horizontallyFlipped)
        try container.encode(interactive, forKey: .interactive)
    }

}
