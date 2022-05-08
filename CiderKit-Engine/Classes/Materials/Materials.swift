import Foundation

public enum MaterialsError: Error {
    case alreadyExisting
    case notRegistered
}

final public class Materials {
    
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
    
}
