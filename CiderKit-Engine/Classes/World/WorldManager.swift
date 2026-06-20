public actor WorldManager {

    private var loadedMaps = [WorldLoadedMapData]()

    public var activeMapModel: MapModel? { loadedMaps.first { $0.isActive }?.model }

    @discardableResult
    public func addEmptyMap() async -> MapModel {
        let mustBeActive = loadedMaps.isEmpty

        let mapModel = MapModel()
        add(map: mapModel, file: nil, asActive: mustBeActive)
        return mapModel
    }

    public func loadMap(file: URL) async throws -> MapModel {
        let mustBeActive = loadedMaps.isEmpty

        let mapDescription: MapDescription = try Functions.load(file)
        let mapModel = await MapModel(with: mapDescription)
        add(map: mapModel, file: file, asActive: mustBeActive)
        return mapModel
    }

    private func add(map: MapModel, file: URL?, asActive: Bool) {
        let loadedMapData = WorldLoadedMapData(isActive: asActive, file: file, model: map)
        loadedMaps.append(loadedMapData)
    }

    public func unloadMap(file: URL) {
        loadedMaps.removeAll { $0.file == file }
    }

    public func unloadAllMaps() {
        loadedMaps.removeAll()
    }

    public func setActiveScene(file: URL) {
        guard let mapIndex = loadedMaps.firstIndex(where: { $0.file == file }) else {
            return
        }

        if let activeMapIndex = loadedMaps.firstIndex(where: { $0.isActive }), activeMapIndex != mapIndex {
            loadedMaps[activeMapIndex] = loadedMaps[activeMapIndex].with(isActive: false)
        }

        loadedMaps[mapIndex] = loadedMaps[mapIndex].with(isActive: true)
    }

}
