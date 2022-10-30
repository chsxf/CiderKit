import Foundation

public enum MaterialFactoryErrors: Error {
    
    case alreadyRegistered
    case notRegistered
    case instantiationFailed
    
}

final public class MaterialFactory {
    
    private static var materialByTypeName: [String:BaseMaterial.Type] = [:]
    
    public static func registerBuiltinMaterialTypes() {
        try! Self.registerMaterialType(SingleTextureMaterial.self, of: "single_texture")
    }
    
    public static func registerMaterialType(_ type: BaseMaterial.Type, of typeName: String) throws {
        if let _ = materialByTypeName[typeName] {
            throw MaterialFactoryErrors.alreadyRegistered
        }
        materialByTypeName[typeName] = type
    }
    
    public static func instantiateMaterial(of typeName: String, dataContainer: KeyedDecodingContainer<StringCodingKey>) throws -> BaseMaterial {
        guard let materialType = materialByTypeName[typeName] else {
            throw MaterialFactoryErrors.notRegistered
        }
        do {
            return try materialType.init(dataContainer: dataContainer)
        }
        catch {
            throw MaterialFactoryErrors.instantiationFailed
        }
    }
    
}
