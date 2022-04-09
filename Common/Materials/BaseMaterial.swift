import Foundation
import SpriteKit

open class BaseMaterial {
    
    public static let actionKey: String = "material"
    
    public let shader: SKShader?
    public let shared: Bool
    
    internal let spriteSequences: [SKAction]
    
    internal init(spriteSequences: [SKAction], shader: SKShader? = nil, shared: Bool = true) {
        self.spriteSequences = spriteSequences
        self.shader = shader
        self.shared = shared
    }
    
    public convenience init(spriteSequence: SKAction, shader: SKShader? = nil, shared: Bool = true) {
        self.init(spriteSequences: [spriteSequence], shader: shader, shared: shared)
    }
    
    public convenience init(sprite: SKTexture, shader: SKShader? = nil, shared: Bool = true) {
        let sequence = SKAction.setTexture(sprite, resize: true)
        self.init(spriteSequence: sequence, shader: shader, shared: shared)
    }
    
    open func nextSpriteSequence() -> SKAction {
        return spriteSequences[0]
    }
    
    open func reset() { }
    
    open func clone() -> BaseMaterial {
        return BaseMaterial(spriteSequences: spriteSequences, shader: shader, shared: shared)
    }
    
    public final func applyOn(spriteNode: SKSpriteNode) {
        spriteNode.shader = shader
        spriteNode.run(nextSpriteSequence(), withKey: Self.actionKey)
    }
    
}
