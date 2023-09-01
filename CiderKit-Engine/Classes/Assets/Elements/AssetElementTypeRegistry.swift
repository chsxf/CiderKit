public enum AssetElementTypeRegistryErrors: Error {
    
    case alreadyRegisterd
    case unknownType(name: String)
    
}

public final class AssetElementTypeRegistry {
    
    private static var registry: [String:TransformAssetElement.Type] = [:]
    
    public static var allRegistered: [TransformAssetElement.Type] = [TransformAssetElement.Type](registry.values)
    
    public static func register(type: TransformAssetElement.Type, named name: String) throws {
        guard registry[name] == nil else {
            throw AssetElementTypeRegistryErrors.alreadyRegisterd
        }
        
        registry[name] = type
    }
    
    static func get(named name: String) throws -> TransformAssetElement.Type {
        guard let type = registry[name] else {
            throw AssetElementTypeRegistryErrors.unknownType(name: name)
        }
        return type
    }
    
    static func registerBuiltinTypes() {
        try! register(type: ReferenceAssetElement.self, named: "reference")
        try! register(type: TransformAssetElement.self, named: "transform")
        try! register(type: SpriteAssetElement.self, named: "sprite")
    }
    
}
