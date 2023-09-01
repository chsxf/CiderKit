public enum AssetElementViewTypeRegistryErrors: Error {
    
    case alreadyRegisterd
    case unknownType(name: String)
    
}

public final class AssetElementViewTypeRegistry {
    
    private static var registry: [String:TransformAssetElementView.Type] = [:]
    
    public static var allRegistered: [TransformAssetElementView.Type] = [TransformAssetElementView.Type](registry.values)
    
    public static func register(type: TransformAssetElementView.Type, named name: String) throws {
        guard registry[name] == nil else {
            throw AssetElementViewTypeRegistryErrors.alreadyRegisterd
        }
        
        registry[name] = type
    }
    
    static func get(named name: String) throws -> TransformAssetElementView.Type {
        guard let type = registry[name] else {
            throw AssetElementViewTypeRegistryErrors.unknownType(name: name)
        }
        return type
    }
    
    static func registerBuiltinTypes() {
        try! register(type: ReferenceAssetElementView.self, named: "reference")
        try! register(type: SpriteAssetElementView.self, named: "sprite")
        try! register(type: TransformAssetElementView.self, named: "transform")
    }
    
}
