internal struct WorldLoadedMapData {

    public let isActive: Bool
    public let file: URL?
    public let model: MapModel

    public func with(isActive newIsActive: Bool) -> WorldLoadedMapData {
        WorldLoadedMapData(isActive: newIsActive, file: file, model: model)
    }

}
