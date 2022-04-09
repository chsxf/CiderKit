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
    
    public static subscript(name: String) -> BaseMaterial {
        get throws {
            guard let material = Self.materials[name] else {
                throw MaterialsError.notRegistered
            }
            return material.shared ? material : material.clone()
        }
    }
    
}
