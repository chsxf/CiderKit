import Foundation

public enum MaterialsError: Error {
    case alreadyExisting
    case notRegistered
}

final public class Materials: Decodable {
    
    enum TopLevelCodingKeys: String, CodingKey {
        case materials
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case data
    }
    
    private static var materials: [String: BaseMaterial] = [:]
    
    public static func register(material: BaseMaterial, forName name: String) throws {
        if Self.materials[name] != nil {
            throw MaterialsError.alreadyExisting
        }
        
        materials[name] = material
    }
    
    public static func material(named name: String, withOverrides overrides: CustomSettings?) throws -> BaseMaterial {
        guard let material = Self.materials[name] else {
            throw MaterialsError.notRegistered
        }
        return material.clone(withOverrides: overrides)
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
            try Self.register(material: material, forName: name)
        }
    }
    
}
