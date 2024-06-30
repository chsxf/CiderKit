import GameplayKit

public class AssetComponent: GKComponent {
    
    public let placement: AssetPlacement
    
    public fileprivate(set) var assetInstance: AssetInstance? = nil
    
    fileprivate init(from placement: AssetPlacement) {
        self.placement = placement
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public class func entity(with instance: AssetInstance) -> GKEntity {
        let newEntity = GKEntity()
        
        newEntity.addComponent(GKSKNodeComponent(node: instance.node!))
        
        let assetComponent = AssetComponent(from: instance.placement)
        assetComponent.assetInstance = instance
        newEntity.addComponent(assetComponent)
        
        return newEntity
    }

    public func contains(sceneCoordinates: ScenePosition) -> Bool {
        guard let node = entity?.component(ofType: GKSKNodeComponent.self)?.node else {
            return false
        }
        return node.calculateAccumulatedFrame().contains(sceneCoordinates)
    }

}
