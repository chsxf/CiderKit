import Foundation
import SpriteKit
import CiderKit_Engine

class PointLightNode: SKNode {

    let lightbulbOnNode: SKSpriteNode
    let lightbulbOffNode: SKSpriteNode
    
    var enabled: Bool {
        get { lightbulbOffNode.isHidden }
        set {
            lightbulbOffNode.isHidden = newValue
            lightbulbOnNode.isHidden = !newValue
        }
    }
    
    var selected: Bool = false {
        didSet {
            updateSpriteColor()
        }
    }
    
    var hovered: Bool = false {
        didSet {
            updateSpriteColor()
        }
    }
    
    override init() {
        lightbulbOnNode = SKSpriteNode(imageNamed: "lightbulb_on")
        lightbulbOffNode = SKSpriteNode(imageNamed: "lightbulb_off")
        
        super.init()

        zPosition = 1000
        
        setupLightBulb(lightbulbOnNode)
        setupLightBulb(lightbulbOffNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupLightBulb(_ lightbulb: SKSpriteNode) {
        lightbulb.setScale(0.33)
        lightbulb.color = LightColor.white
        lightbulb.colorBlendFactor = 1.0
        addChild(lightbulb)
    }
    
    fileprivate func updateSpriteColor() {
        if !selected && !hovered {
            setSpriteColor(LightColor.white)
        }
        else {
            let color = selected ? LightColor.green : LightColor.red
            setSpriteColor(color)
        }
    }
    
    fileprivate func setSpriteColor(_ color: LightColor) {
        lightbulbOnNode.color = color
        lightbulbOffNode.color = color
    }
    
}
