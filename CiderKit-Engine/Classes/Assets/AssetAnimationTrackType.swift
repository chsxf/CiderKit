import Foundation

public enum AssetAnimationTrackTypeErrors: Error {
    case alreadyRegistered
}

public struct AssetAnimationTrackType: Hashable, Sendable {
    
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

}
