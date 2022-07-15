import SpriteKit

class ToolNode<ContextType>: SKNode where ContextType: ToolContext {
    
    private let sprites: [ContextType: SKSpriteNode]
    
    init(withContext: ContextType.Type) {
        var dict: [ContextType: SKSpriteNode] = [:]
        for context in ContextType.allCases {
            let texture = SKTexture(imageNamed: String(format: context.spriteImageFormat, "\(context)"))
            texture.filteringMode = .nearest
            let sprite = SKSpriteNode(texture: texture)
            sprite.color = context.color
            sprite.colorBlendFactor = 1
            dict[context] = sprite
        }
        
        sprites = dict
        
        super.init()
        
        for entry in self.sprites {
            addChild(entry.value)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func highlight(context: ContextType) {
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
