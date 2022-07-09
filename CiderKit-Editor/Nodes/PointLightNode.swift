import Foundation
import SpriteKit
import CiderKit_Engine

class PointLightNode: SKNode {

    private static var lightbulbOnTexture: SKTexture? = nil
    private static var lightbulbOfftexture: SKTexture? = nil
    
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
        if Self.lightbulbOnTexture == nil {
            Self.lightbulbOnTexture = SKTexture(imageNamed: "lightbulb_on")
            Self.lightbulbOnTexture?.filteringMode = .nearest
        }
        
        if Self.lightbulbOfftexture == nil {
            Self.lightbulbOfftexture = SKTexture(imageNamed: "lightbulb_off")
            Self.lightbulbOfftexture?.filteringMode = .nearest
        }
        
        lightbulbOnNode = SKSpriteNode(texture: Self.lightbulbOnTexture)
        lightbulbOffNode = SKSpriteNode(texture: Self.lightbulbOfftexture)
        
        super.init()
        
        setupLightBulb(lightbulbOnNode)
        setupLightBulb(lightbulbOffNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupLightBulb(_ lightbulb: SKSpriteNode) {
        lightbulb.setScale(0.33)
        lightbulb.color = SKColor.white
        lightbulb.colorBlendFactor = 1.0
        addChild(lightbulb)
    }
    
    fileprivate func updateSpriteColor() {
        if !selected && !hovered {
            setSpriteColor(SKColor.white)
        }
        else {
            let color = selected ? SKColor.green : SKColor.red
            setSpriteColor(color)
        }
    }
    
    fileprivate func setSpriteColor(_ color: SKColor) {
        lightbulbOnNode.color = color
        lightbulbOffNode.color = color
    }
    
}
