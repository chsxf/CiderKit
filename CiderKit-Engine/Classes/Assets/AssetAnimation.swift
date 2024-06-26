public final class AssetAnimation: Codable {
    
    enum CodingKeys: String, CodingKey {
        case animationTracks = "tracks"
    }
    
    public var animationTracks: [AssetAnimationTrackIdentifier: AssetAnimationTrack] = [:] {
        didSet {
            refreshReferencedElementUUIDs()
        }
    }
    
    public private(set) var referenceElementUUIDs = Set<UUID>()
    
    public init() { }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let tracksContainer = try container.nestedContainer(keyedBy: AssetAnimationTrackIdentifier.self, forKey: .animationTracks)
        var tracks = [AssetAnimationTrackIdentifier: AssetAnimationTrack]()
        for key in tracksContainer.allKeys {
            let track = try tracksContainer.decode(AssetAnimationTrack.self, forKey: key)
            tracks[key] = track
        }
        animationTracks = tracks
        refreshReferencedElementUUIDs()
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
        refreshReferencedElementUUIDs()
    }
    
    private func refreshReferencedElementUUIDs() {
        referenceElementUUIDs.removeAll()
        for (identifier, _) in animationTracks {
            referenceElementUUIDs.insert(identifier.elementUUID)
        }
    }

    public func remapElementUUIDs(map: [UUID: UUID]) {
        let oldTrackIdentifiers = animationTracks.keys
        for oldIdentifier in oldTrackIdentifiers {
            let oldUUID = oldIdentifier.elementUUID
            let newUUID = map[oldUUID]!
            let newIdentifier = AssetAnimationTrackIdentifier(elementUUID: newUUID, type: oldIdentifier.trackType)
            animationTracks[newIdentifier] = animationTracks[oldIdentifier]
            animationTracks[oldIdentifier] = nil
        }

        refreshReferencedElementUUIDs()
    }

}
