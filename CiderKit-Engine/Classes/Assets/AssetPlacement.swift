public final class AssetPlacement: Identifiable, ObservableObject, NamedObject {

    public let id: UUID
    public let assetLocator: AssetLocator
    @Published public var name: String
    @Published public var mapPosition: MapPosition
    @Published public var horizontallyFlipped: Bool
    @Published public var interactive: Bool
    
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
    
    public func toDescription() -> AssetPlacementDescription {
        AssetPlacementDescription(id: id,
                                  assetLocator: assetLocator,
                                  horizontallyFlipped: horizontallyFlipped,
                                  position: mapPosition,
                                  name: name,
                                  interactive: interactive)
    }

}
