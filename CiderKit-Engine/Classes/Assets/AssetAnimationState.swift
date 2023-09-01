public final class AssetAnimationState: Codable {
    
    enum CodingKeys: String, CodingKey {
        case animationTracks = "tracks"
    }
    
    public var animationTracks: [AssetAnimationTrackIdentifier:AssetAnimationTrack] = [:]
    
    public init() { }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let tracksContainer = try container.nestedContainer(keyedBy: AssetAnimationTrackIdentifier.self, forKey: .animationTracks)
        for key in tracksContainer.allKeys {
            let track = try tracksContainer.decode(AssetAnimationTrack.self, forKey: key)
            animationTracks[key] = track
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var trackContainer = container.nestedContainer(keyedBy: AssetAnimationTrackIdentifier.self, forKey: .animationTracks)
        for (identifier, track) in animationTracks {
            try trackContainer.encode(track, forKey: identifier)
        }
    }
    
    public func hasAnimationTrack(_ type: AssetAnimationTrackType, for elementUUID: UUID) -> Bool {
        let identifier = AssetAnimationTrackIdentifier(elementUUID: elementUUID, type: type)
        return animationTracks[identifier] != nil
    }
    
    public func removeAnimationTracks(for elementUUID: UUID) {
        animationTracks = animationTracks.filter { $0.key.elementUUID != elementUUID }
    }
    
}
