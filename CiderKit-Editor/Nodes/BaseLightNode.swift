import Foundation
import SpriteKit
import CiderKit_Engine

class BaseLightNode: SKNode {

    let onNode: SKSpriteNode
    let offNode: SKSpriteNode
    
    let ringNode: SKShapeNode
    
    var enabled: Bool {
        get { offNode.isHidden }
        set {
            offNode.isHidden = newValue
            onNode.isHidden = !newValue
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

    init(onTexture: SKTexture, offTexture: SKTexture) {
        onNode = SKSpriteNode(texture: onTexture)
        offNode = SKSpriteNode(texture: offTexture)
        
        ringNode = SKShapeNode(circleOfRadius: 5)
        ringNode.strokeColor = .gray
        ringNode.fillColor = .black
        
        super.init()
        
        addChild(ringNode)
        
        setupSpriteNode(onNode)
        setupSpriteNode(offNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLightColor(_ color: CGColor) {
        ringNode.fillColor = SKColorFromCGColor(color)
    }
    
    fileprivate func setupSpriteNode(_ spriteNode: SKSpriteNode) {
        spriteNode.setScale(0.33)
        spriteNode.color = SKColor.white
        spriteNode.colorBlendFactor = 1.0
        addChild(spriteNode)
    }
    
    fileprivate func updateSpriteColor() {
        if !selected && !hovered {
            ringNode.strokeColor = .gray
        }
        else {
            let color = selected ? SKColor.green : SKColor.red
            ringNode.strokeColor = color
        }
    }
    
}
