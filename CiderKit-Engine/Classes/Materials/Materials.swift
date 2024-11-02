import Foundation

final public class Materials: Decodable {
    
    enum TopLevelCodingKeys: String, CodingKey {
        case materials
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case data
    }
    
    public required init(from decoder: Decoder) throws {
        let topLevelContainer = try decoder.container(keyedBy: TopLevelCodingKeys.self)
        
        var materials = try topLevelContainer.nestedUnkeyedContainer(forKey: .materials)
        while !materials.isAtEnd {
            let materialContainer = try materials.nestedContainer(keyedBy: CodingKeys.self)
            
            let name = try materialContainer.decode(String.self, forKey: .name)
            let type = try materialContainer.decode(String.self, forKey: .type)
            
            let dataContainer = try materialContainer.nestedContainer(keyedBy: StringCodingKey.self, forKey: .data)
            let material = try MaterialFactory.instantiateMaterial(named: type, dataContainer: dataContainer)
            try MaterialRegistry.register(material: material, forName: name)
        }
    }
    
}
