import os

public enum AssetElementTypeRegistryErrors: Error {

    case alreadyRegisterd
    case unknownType(name: String)
    
}

public final class AssetElementTypeRegistry {

    private static let registry: OSAllocatedUnfairLock<[String: TransformAssetElement.Type]> = OSAllocatedUnfairLock(initialState: [:])

    public static var allRegistered: [TransformAssetElement.Type] {
        let values = registry.withLock { return $0.values }
        return [TransformAssetElement.Type](values)
    }

    public static func register(type: TransformAssetElement.Type, named name: String) throws {
        guard registry.withLock({ $0[name] }) == nil else {
            throw AssetElementTypeRegistryErrors.alreadyRegisterd
        }
        registry.withLock { $0[name] = type }
    }
    
    static func get(named name: String) throws -> TransformAssetElement.Type {
        guard let type = registry.withLock({ $0[name] }) else {
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
