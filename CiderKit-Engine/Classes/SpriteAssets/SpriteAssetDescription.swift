import Combine

public class SpriteAssetDescription: Identifiable, Codable, ObservableObject {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
    }
    
    public var id: UUID = UUID()
    @Published public var name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: CodingKeys.id)
        name = try container.decode(String.self, forKey: CodingKeys.name)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: CodingKeys.id)
        try container.encode(name, forKey: CodingKeys.name)
    }
    
}
