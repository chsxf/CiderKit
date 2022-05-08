import Foundation
import SpriteKit

open class BaseMaterial {
    
    public enum Overrides: String {
        case sequenceIndex = "si"
    }
    
    public static let actionKey: String = "material"
    
    public let shader: SKShader?
    
    internal let spriteSequences: [SKAction]
    
    public init(spriteSequences: [SKAction], shader: SKShader? = nil) {
        self.spriteSequences = spriteSequences
        self.shader = shader
    }
    
    public convenience init(spriteSequence: SKAction, shader: SKShader? = nil) {
        self.init(spriteSequences: [spriteSequence], shader: shader)
    }
    
    public convenience init(sprite: SKTexture, shader: SKShader? = nil) {
        let sequence = SKAction.setTexture(sprite, resize: true)
        self.init(spriteSequence: sequence, shader: shader)
    }
    
    public convenience init(sprites: [SKTexture], shader: SKShader? = nil) {
        var spriteSequences = [SKAction]()
        for sprite in sprites {
            spriteSequences.append(SKAction.setTexture(sprite, resize: true))
        }
        self.init(spriteSequences: spriteSequences, shader: shader)
    }
    
    open func nextSpriteSequence(withLocalOverrides localOverrides: CustomSettings?) -> SKAction {
        let sequenceIndex: Int = localOverrides?.getInt(for: Overrides.sequenceIndex.rawValue) ?? 0
        return spriteSequences[sequenceIndex]
    }
    
    open func reset() { }
    
    open func clone(withOverrides overrides: CustomSettings?) -> BaseMaterial {
        return BaseMaterial(spriteSequences: spriteSequences, shader: shader)
    }
    
    public final func applyOn(spriteNode: SKSpriteNode, withLocalOverrides localOverrides: CustomSettings?) {
        spriteNode.shader = shader
        let spriteSequenceAction = nextSpriteSequence(withLocalOverrides: localOverrides)
        spriteNode.run(spriteSequenceAction, withKey: Self.actionKey)
    }
    
}
