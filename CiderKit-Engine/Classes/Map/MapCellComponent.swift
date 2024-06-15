import GameplayKit

open class MapCellComponent: GKComponent
{
    public private(set) weak var region: MapRegion?
    
    public var position: MapPosition
    
    var groundMaterialOverrides: CustomSettings? = nil
    var leftElevationMaterialOverrides: CustomSettings? = nil
    var rightElevationMaterialOverrides: CustomSettings? = nil
    
    public init(region: MapRegion?, position: MapPosition) {
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
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else {
            return false
        }
        
        var result = false
        
        let bounds = node.frame
        if bounds.contains(sceneCoordinates) {
            let normalizedLocalX = (sceneCoordinates.x - bounds.minX) / bounds.width
            let normalizedLocalY = (sceneCoordinates.y - bounds.minY) / bounds.height
            
            result = true
            if (normalizedLocalX < 0.5 && (normalizedLocalY > 0.5 + normalizedLocalX || normalizedLocalY < 0.5 - normalizedLocalX))
                || (normalizedLocalX > 0.5 && (normalizedLocalY > 1.5 - normalizedLocalX || normalizedLocalY < normalizedLocalX - 0.5)) {
                result = false
            }
        }
        
        return result
    }
}
