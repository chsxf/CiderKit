public final class AssetPlacement: Identifiable, UpdatableObject, NamedObject {

    typealias AssetPlacementEventData = (stream: AsyncStream<Void>, continuation: AsyncStream<Void>.Continuation)

    private var updateStreams = [AssetPlacementEventData]()
    public var updated: AsyncStream<Void> { Self.makeStream(streamArray: &updateStreams) }

    public let id: UUID
    public let assetLocator: AssetLocator
    public var name: String
    public var mapPosition: MapPosition
    public var horizontallyFlipped: Bool
    public var interactive: Bool
    
    public init(description: AssetPlacementDescription) {
        id = description.id
        assetLocator = description.assetLocator
        name = description.name
        mapPosition = description.mapPosition
        horizontallyFlipped = description.horizontallyFlipped
        interactive = description.interactive
    }
    
    public init(assetLocator: AssetLocator, horizontallyFlipped: Bool, position: MapPosition = MapPosition(), name: String = "") {
        id = UUID()
        self.name = name
        self.assetLocator = assetLocator
        self.mapPosition = position
        self.horizontallyFlipped = horizontallyFlipped
        interactive = false
    }

    deinit {
        updateStreams.forEach { $0.continuation.finish() }
    }

    public func rename(_ newName: String) async {
        name = newName
    }

    public func toDescription() -> AssetPlacementDescription {
        AssetPlacementDescription(id: id,
                                  assetLocator: assetLocator,
                                  name: name,
                                  mapPosition: mapPosition,
                                  horizontallyFlipped: horizontallyFlipped,
                                  interactive: interactive)
    }

    public func notifyUpdate() {
        updateStreams.forEach { $0.continuation.yield() }
    }

    private static func makeStream(streamArray: inout [AssetPlacementEventData]) -> AsyncStream<Void> {
        let streamData = AsyncStream<Void>.makeStream(bufferingPolicy: .unbounded)
        streamArray.append(streamData)
        return streamData.stream
    }

}
