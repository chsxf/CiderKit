import SpriteKit
import GameplayKit

open class SequenceMaterial: BaseMaterial {
    
    public let sprites: [SKTexture]
    public let frameDuration: TimeInterval
    public var firstFrame: Int
    
    public init(sprites: [SKTexture], frameDuration: TimeInterval, shader: SKShader) {
        self.sprites = sprites
        self.frameDuration = frameDuration
        self.firstFrame = 0
        super.init(shader: shader)
    }
    
    open override func reset() {
        super.reset()
        firstFrame = GKRandomSource.sharedRandom().nextInt(upperBound: sprites.count)
    }
    
    open override func clone(withOverrides overrides: CustomSettings?) -> BaseMaterial {
        SequenceMaterial(sprites: sprites, frameDuration: frameDuration, shader: shader)
    }
    
    public override func toSKAction() -> SKAction {
        var spritesToUse: [SKTexture]
        if firstFrame == 0 {
            spritesToUse = sprites
        }
        else {
            spritesToUse = [SKTexture]()
            spritesToUse.append(contentsOf: sprites[firstFrame..<sprites.count])
            spritesToUse.append(contentsOf: sprites[0..<firstFrame])
        }
        
        return SKAction.repeatForever(
            SKAction.animate(with: spritesToUse, timePerFrame: frameDuration, resize: true, restore: false)
        )
    }
    
}
