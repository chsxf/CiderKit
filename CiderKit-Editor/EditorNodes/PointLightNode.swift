import Foundation
import SpriteKit
import CiderKit_Engine

class PointLightNode: SKNode {
    
    let lightDescription: PointLight
    
    init(from description: PointLight) {
        lightDescription = description
        
        super.init()

        let xyPosition = CGPoint(x: CGFloat(lightDescription.position.x), y: CGFloat(lightDescription.position.y))
        position = Math.worldToScene(xyPosition, halfTileSize: CGSize(width: MapNode.halfWidth, height: MapNode.halfHeight))
        position.y += CGFloat(lightDescription.position.z) * CGFloat(MapNode.elevationHeight)
        zPosition = 1000
        
        let imageName = lightDescription.enabled ? "lightbulb_on" : "lightbulb_off"
        let lightbulbSprite = SKSpriteNode(imageNamed: imageName)
        lightbulbSprite.setScale(0.25)
        lightbulbSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(lightbulbSprite)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
