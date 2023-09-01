public struct AssetAnimationTrackIdentifier: Hashable, CustomStringConvertible, CodingKey {
    
    public var intValue: Int? = nil
    public var stringValue: String { description }
    
    public let elementUUID: UUID
    public let trackType: AssetAnimationTrackType
    
    public var description: String { "\(elementUUID):\(trackType.name)" }
    
    public init(elementUUID: UUID, type: AssetAnimationTrackType) {
        self.elementUUID = elementUUID
        self.trackType = type
    }
    
    public init?(intValue: Int) { nil }
    
    public init?(stringValue: String) {
        let chunks = stringValue.split(separator: ":")
        if let elementUUID = UUID(uuidString: String(chunks[0])), let trackType = AssetAnimationTrackType.get(registered: String(chunks[1])) {
            self.elementUUID = elementUUID
            self.trackType = trackType
        }
        else {
            return nil
        }
    }
    
}
