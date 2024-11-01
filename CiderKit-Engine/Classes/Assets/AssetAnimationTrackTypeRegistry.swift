final actor AssetAnimationTrackTypeRegistry {

    private static var registry: [String: AssetAnimationTrackType] = [:]

    public static func register(_ trackType: AssetAnimationTrackType) throws {
        if registry[trackType.name] != nil {
            throw AssetAnimationTrackTypeErrors.alreadyRegistered
        }
        registry[trackType.name] = trackType
    }

    public static func get(registered name: String) -> AssetAnimationTrackType? {
        return registry[name]
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
