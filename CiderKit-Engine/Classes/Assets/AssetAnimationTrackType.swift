import Foundation

public enum AssetAnimationTrackTypeErrors: Error {
    case alreadyRegistered
}

public struct AssetAnimationTrackType: Hashable {
    
    public let name: String
    public let displayName: String
    public let systemSymbolName: String
    
    init(name: String, displayName: String, systemSymbolName: String) {
        self.name = name
        self.displayName = displayName
        self.systemSymbolName = systemSymbolName
    }

    public static let color = Self.init(name: "color", displayName: "Color", systemSymbolName: "paintpalette.fill")
    public static let colorBlendFactor = Self.init(name: "colorBlendFactor", displayName: "Color Blend Factor", systemSymbolName: "eyedropper.halffull")
    public static let sprite = Self.init(name: "sprite", displayName: "Sprite", systemSymbolName: "photo")
    public static let visibility = Self.init(name: "visibility", displayName: "Visibility", systemSymbolName: "eye.fill")
    
    private static var registry: [String: Self] = [:]
    
    public static func register(_ trackType: Self) throws {
        if registry[trackType.name] != nil {
            throw AssetAnimationTrackTypeErrors.alreadyRegistered
        }
        registry[trackType.name] = trackType
    }
    
    public static func get(registered name: String) -> Self? {
        return registry[name]
    }
    
    public static func registerBuiltinTypes() {
        try! register(color)
        try! register(colorBlendFactor)
        try! register(sprite)
        try! register(xWorldOffset)
        try! register(yWorldOffset)
        try! register(zWorldOffset)
        try! register(visibility)
    }

}
