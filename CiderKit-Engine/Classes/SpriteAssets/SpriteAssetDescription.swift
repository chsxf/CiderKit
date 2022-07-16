import Combine

public class SpriteAssetDescription: Identifiable, Codable, ObservableObject {
    
    enum CodingKeys: String, CodingKey {
        case uuid = "uuid"
        case name = "name"
        case rootElement = "root"
    }
    
    public var id: String { uuid.description }
    
    let uuid: UUID
    @Published public var name: String
    
    public var rootElement: SpriteAssetElement
    
    public init(name: String) {
        self.name = name
        uuid = UUID()
        
        rootElement = SpriteAssetElement(name: "root")
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uuid = try container.decode(UUID.self, forKey: CodingKeys.uuid)
        name = try container.decode(String.self, forKey: CodingKeys.name)
        rootElement = try container.decode(SpriteAssetElement.self, forKey: CodingKeys.rootElement)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uuid, forKey: CodingKeys.uuid)
        try container.encode(name, forKey: CodingKeys.name)
        try container.encode(rootElement, forKey: CodingKeys.rootElement)
    }
    
}
