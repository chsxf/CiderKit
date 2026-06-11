public struct AssetPlacementDescription: Codable, Identifiable, Sendable {

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

    private static let VERSION = AssetPlacementDescription.WITH_MAP_POSITION_VERSION

    public let version: Int = AssetPlacementDescription.VERSION
    public let id: UUID
    public let assetLocator: AssetLocator
    public let name: String
    public let mapPosition: MapPosition
    public let horizontallyFlipped: Bool
    public let interactive: Bool
    
    public init(id: UUID, assetLocator: AssetLocator, horizontallyFlipped: Bool, position: MapPosition = MapPosition(), name: String = "", interactive: Bool = false) {
        self.id = id
        self.name = name
        self.assetLocator = assetLocator
        self.mapPosition = position
        self.horizontallyFlipped = horizontallyFlipped
        self.interactive = interactive
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let savedVersion = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        assetLocator = try container.decode(AssetLocator.self, forKey: .assetLocator)
        if savedVersion < Self.WITH_MAP_POSITION_VERSION {
            let x = try container.decode(Int.self, forKey: .x)
            let y = try container.decode(Int.self, forKey: .y)
            let worldOffset = try container.decode(CGPoint.self, forKey: .worldOffset)
            let simdWorldOffset = WorldPosition(Float(worldOffset.x), Float(worldOffset.y), 0)
            mapPosition = MapPosition(x: x, y: y, worldOffset: simdWorldOffset)
        }
        else {
            mapPosition = try container.decode(MapPosition.self, forKey: .position)
        }
        horizontallyFlipped = try container.decodeIfPresent(Bool.self, forKey: .horizontallyFlipped) ?? false
        interactive = try container.decodeIfPresent(Bool.self, forKey: .interactive) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(version, forKey: .version)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(assetLocator, forKey: .assetLocator)
        try container.encode(mapPosition, forKey: .position)
        try container.encode(horizontallyFlipped, forKey: .horizontallyFlipped)
        try container.encode(interactive, forKey: .interactive)
    }
    
    public func with(newPosition: MapPosition) -> Self {
        AssetPlacementDescription(id: id,
                                  assetLocator: assetLocator,
                                  horizontallyFlipped: horizontallyFlipped,
                                  position: newPosition,
                                  name: name,
                                  interactive: interactive)
    }

}
