import os

final class AssetAnimationTrackTypeRegistry {

    private static let registry: OSAllocatedUnfairLock<[String: AssetAnimationTrackType]> = OSAllocatedUnfairLock(initialState: [:])

    public static func register(_ trackType: AssetAnimationTrackType) throws {
        if registry.withLock({ $0[trackType.name] }) != nil {
            throw AssetAnimationTrackTypeErrors.alreadyRegistered
        }
        registry.withLock { $0[trackType.name] = trackType }
    }

    public static func get(registered name: String) -> AssetAnimationTrackType? {
        return registry.withLock({ $0[name] })
    }

    public static func registerBuiltinTypes() {
        try! register(AssetAnimationTrackType.color)
        try! register(AssetAnimationTrackType.colorBlendFactor)
        try! register(AssetAnimationTrackType.sprite)
        try! register(AssetAnimationTrackType.xWorldOffset)
        try! register(AssetAnimationTrackType.yWorldOffset)
        try! register(AssetAnimationTrackType.zWorldOffset)
        try! register(AssetAnimationTrackType.visibility)
    }

}
