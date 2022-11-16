import Foundation

public enum MaterialFactoryErrors: Error {
    
    case alreadyRegistered
    case notRegistered
    case instantiationFailed
    
}

final public class MaterialFactory {
    
    private static var materialByTypeName: [String:BaseMaterial.Type] = [:]
    
    private static var builtinMaterialTypesRegistered: Bool = false
    
    public static func registerBuiltinMaterialTypes() {
        if !Self.builtinMaterialTypesRegistered {
            try! Self.registerMaterialType(SingleTextureMaterial.self, named: "single_texture")
            try! Self.registerMaterialType(SequenceMaterial.self, named: "sequence")
            Self.builtinMaterialTypesRegistered = true
        }
    }
    
    public static func registerMaterialType(_ type: BaseMaterial.Type, named typeName: String) throws {
        if let _ = materialByTypeName[typeName] {
            throw MaterialFactoryErrors.alreadyRegistered
        }
        materialByTypeName[typeName] = type
    }
    
    public static func instantiateMaterial(named typeName: String, dataContainer: KeyedDecodingContainer<StringCodingKey>) throws -> BaseMaterial {
        Self.registerBuiltinMaterialTypes()
        
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
