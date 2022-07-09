import SpriteKit

class MoveToolNode: SKNode {
    
    let sprites: [MoveToolContext:SKSpriteNode]
    
    override init() {
        var dict: [MoveToolContext: SKSpriteNode] = [:]
        for context in MoveToolContext.allCases {
            let texture = SKTexture(imageNamed: "MoveTool-\(context)-arrow")
            texture.filteringMode = .nearest
            let sprite = SKSpriteNode(texture: texture)
            sprite.color = context.color
            sprite.colorBlendFactor = 1
            dict[context] = sprite
        }
        sprites = dict
        
        super.init()
        
        for entry in sprites {
            addChild(entry.value)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func highlight(context: MoveToolContext) {
        for spriteEntry in sprites {
            if spriteEntry.0 == context {
                spriteEntry.1.color = SKColor.yellow
            }
            else {
                spriteEntry.1.color = spriteEntry.0.color
            }
        }
    }
    
    func resetAllContexts() {
        for spriteEntry in sprites {
            spriteEntry.1.color = spriteEntry.0.color
        }
    }
    
}
