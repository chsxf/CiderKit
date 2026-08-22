public final class AssetPlacement: Identifiable, UpdatableObject, NamedObject {

    typealias AssetPlacementEventData = (stream: AsyncStream<Void>, continuation: AsyncStream<Void>.Continuation)

    private var updateStreams = [AssetPlacementEventData]()
    public var updated: AsyncStream<Void> { Self.makeStream(streamArray: &updateStreams) }

    public private(set) var placementDescription: AssetPlacementDescription

    public var id: UUID { placementDescription.id }
    public var assetLocator: AssetLocator { placementDescription.assetLocator }
    public var name: String { placementDescription.name }
    public var mapPosition: MapPosition { placementDescription.mapPosition }
    public var horizontallyFlipped: Bool { placementDescription.horizontallyFlipped }
    public var interactive: Bool { placementDescription.interactive }

    public init(description: AssetPlacementDescription) {
        placementDescription = description
    }
    
    public init(assetLocator: AssetLocator, horizontallyFlipped: Bool, position: MapPosition = MapPosition(), name: String = "") {
        placementDescription = AssetPlacementDescription(id: UUID(), assetLocator: assetLocator, name: name, mapPosition: position, horizontallyFlipped: horizontallyFlipped, interactive: false)
    }

    deinit {
        updateStreams.forEach { $0.continuation.finish() }
    }

    public func match(description newDescription: AssetPlacementDescription) {
        guard placementDescription.id != newDescription.id || placementDescription.version != newDescription.version else { return }
        placementDescription = newDescription
        notifyUpdate()
    }

    public func rename(_ newName: String) async {
        let newDescription = placementDescription.mutated(withName: newName)
        await MapModel.shared.update(assetPlacement: newDescription)
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
