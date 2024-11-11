import GameplayKit

open class MapCellComponent: GKComponent
{
    public private(set) weak var region: MapRegionNode?
    
    public var position: MapPosition
    
    var groundMaterialOverrides: CustomSettings? = nil
    var leftElevationMaterialOverrides: CustomSettings? = nil
    var rightElevationMaterialOverrides: CustomSettings? = nil
    
    public init(region: MapRegionNode?, position: MapPosition) {
        self.region = region
        self.position = position
        super.init()
    }
    
    public convenience init(x: Int, y: Int) {
        self.init(region: nil, position: MapPosition(x: x, y: y))
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func contains(sceneCoordinates: ScenePosition) -> Bool {
        getContainedWorldPosition(sceneCoordinates: sceneCoordinates) != nil
    }

    public func getContainedWorldPosition(sceneCoordinates: ScenePosition) -> WorldPosition? {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else {
            return nil
        }

        var result: WorldPosition? = nil

        let bounds = node.frame
        if bounds.contains(sceneCoordinates) {
            let normalizedLocalX = (sceneCoordinates.x - bounds.minX) / bounds.width
            let normalizedLocalY = (sceneCoordinates.y - bounds.minY) / bounds.height

            if (normalizedLocalX < 0.5 && (normalizedLocalY > 0.5 + normalizedLocalX || normalizedLocalY < 0.5 - normalizedLocalX))
                || (normalizedLocalX > 0.5 && (normalizedLocalY > 1.5 - normalizedLocalX || normalizedLocalY < normalizedLocalX - 0.5)) {
                result = nil
            }
            else {
                // Compute local scene position from the top corner of the cell
                let localScenePosition = ScenePosition(
                    x: bounds.width * (normalizedLocalX - 0.5),
                    y: bounds.height * (normalizedLocalY - 1)
                )
                let localWorldPosition = MapNode.sceneToWorld(localScenePosition)
                result = WorldPosition(Float(position.x) + localWorldPosition.x, Float(position.y) + localWorldPosition.y, Float(position.elevation ?? 0))
            }
        }

        return result
    }
}
