public struct MapPosition: Codable, Sendable {

    public let x: Int
    public let y: Int
    public let elevation: Int?
    public let worldOffset: WorldPosition

    public var scenePosition: ScenePosition { MapNode.worldToScene(worldPosition) }

    public var worldPosition: WorldPosition { WorldPosition(Float(x), Float(y), Float(elevation ?? 0)) + worldOffset }

    public init(mapCell: MapCellComponent, worldOffset: WorldPosition = WorldPosition()) {
        x = mapCell.position.x
        y = mapCell.position.y
        elevation = mapCell.position.elevation
        self.worldOffset = mapCell.position.worldOffset + worldOffset
    }

    public init(x: Int = 0, y: Int = 0, elevation: Int? = nil, worldOffset: WorldPosition = WorldPosition()) {
        self.x = x
        self.y = y
        self.elevation = elevation
        self.worldOffset = worldOffset
    }

    public func moved(byX x: Int = 0, y: Int = 0, elevation: Int? = nil, worldOffset: WorldPosition = WorldPosition()) -> MapPosition {
        var newElevation: Int? = self.elevation
        if elevation != nil {
            newElevation = (newElevation ?? 0) + elevation!
        }
        return MapPosition(x: x + x, y: y + y, elevation: newElevation, worldOffset: self.worldOffset + worldOffset)
    }

    public func withElevation(_ newElevation: Int? = nil) -> MapPosition {
        MapPosition(x: x, y: y, elevation: newElevation, worldOffset: worldOffset)
    }

}
