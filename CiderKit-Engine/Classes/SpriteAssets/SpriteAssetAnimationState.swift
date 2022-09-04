public class SpriteAssetAnimationState: Codable {
    
    enum CodingKeys: String, CodingKey {
        case animationTracks = "tracks"
    }
    
    public var animationTracks: [SpriteAssetAnimationTrackIdentifier:SpriteAssetAnimationTrack] = [:]
    
    public init() { }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let tracksContainer = try container.nestedContainer(keyedBy: SpriteAssetAnimationTrackIdentifier.self, forKey: .animationTracks)
        for key in tracksContainer.allKeys {
            let track = try tracksContainer.decode(SpriteAssetAnimationTrack.self, forKey: key)
            animationTracks[key] = track
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var trackContainer = container.nestedContainer(keyedBy: SpriteAssetAnimationTrackIdentifier.self, forKey: .animationTracks)
        for (identifier, track) in animationTracks {
            try trackContainer.encode(track, forKey: identifier)
        }
    }
    
    public func hasAnimationTrack(_ type: SpriteAssetAnimationTrackType, for elementUUID: UUID) -> Bool {
        let identifier = SpriteAssetAnimationTrackIdentifier(elementUUID: elementUUID, type: type)
        return animationTracks[identifier] != nil
    }
    
}
