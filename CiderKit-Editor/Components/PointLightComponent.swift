import Foundation
import GameplayKit
import CiderKit_Engine

class PointLightComponent: GKComponent, Selectable {
    
    let lightDescription: PointLight
    
    fileprivate var lightNode: PointLightNode { entity!.component(ofType: GKSKNodeComponent.self)!.node as! PointLightNode }
    
    fileprivate init(from lightDescription: PointLight) {
        self.lightDescription = lightDescription
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contains(sceneCoordinates: CGPoint) -> Bool {
        let light = lightNode
        let frame = light.calculateAccumulatedFrame()
        return frame.contains(sceneCoordinates)
    }

    func hovered() {
        lightNode.hovered = true
    }
    
    func departed() {
        lightNode.hovered = false
    }
    
    func highlight() {
        lightNode.selected = true
    }
    
    func demphasize() {
        lightNode.selected = false
    }
    
    class func entity(from lightDescription: PointLight) -> GKEntity {
        let newEntity = GKEntity();
        
        let xyPosition = CGPoint(x: CGFloat(lightDescription.position.x), y: CGFloat(lightDescription.position.y))
        var scenePosition = Math.worldToScene(xyPosition, halfTileSize: CGSize(width: MapNode.halfWidth, height: MapNode.halfHeight))
        scenePosition.y += CGFloat(lightDescription.position.z) * CGFloat(MapNode.elevationHeight)
        
        let pointLight = PointLightNode()
        pointLight.position = scenePosition
        pointLight.enabled = lightDescription.enabled
        newEntity.addComponent(GKSKNodeComponent(node: pointLight))
        
        newEntity.addComponent(PointLightComponent(from: lightDescription))
        
        return newEntity
    }
    
}
