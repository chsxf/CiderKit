import GameplayKit

public class MapCellComponent: GKComponent
{
    public private(set) weak var region: MapRegion?
    
    public var mapX: Int
    public var mapY: Int
    public let elevation: Int?
    
    var groundMaterialOverrides: CustomSettings? = nil
    var leftElevationMaterialOverrides: CustomSettings? = nil
    var rightElevationMaterialOverrides: CustomSettings? = nil
    
    init(region: MapRegion?, mapX: Int, mapY: Int, elevation: Int?) {
        self.region = region
        self.mapX = mapX
        self.mapY = mapY
        self.elevation = elevation
        
        super.init()
    }
    
    public convenience init(mapX: Int, mapY: Int) {
        self.init(region: nil, mapX: mapX, mapY: mapY, elevation: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func containsScenePosition(_ scenePosition: CGPoint) -> Bool {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else {
            return false
        }
        
        var result = false
        
        let bounds = node.frame
        if bounds.contains(scenePosition) {
            let normalizedLocalX = (scenePosition.x - bounds.minX) / bounds.width
            let normalizedLocalY = (scenePosition.y - bounds.minY) / bounds.height
            
            result = true
            if (normalizedLocalX < 0.5 && (normalizedLocalY > 0.5 + normalizedLocalX || normalizedLocalY < 0.5 - normalizedLocalX))
                || (normalizedLocalX > 0.5 && (normalizedLocalY > 1.5 - normalizedLocalX || normalizedLocalY < normalizedLocalX - 0.5)) {
                result = false
            }
            
        }
        
        return result
    }
}
