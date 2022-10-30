import Foundation
import SpriteKit

open class BaseMaterial {
    
    public static let actionKey: String = "material"
    
    public let shader: SKShader
    
    public init(shader: SKShader) {
        self.shader = shader
    }
    
    open func reset() { }
    
    open func clone(withOverrides overrides: CustomSettings?) -> BaseMaterial {
        return BaseMaterial(shader: shader)
    }
    
    public final func applyOn(spriteNode: SKSpriteNode, withLocalOverrides localOverrides: CustomSettings?) {
        spriteNode.shader = shader
        spriteNode.run(toSKAction())
    }
    
    public func toSKAction() -> SKAction { SKAction(named: Self.actionKey)! }
    
}
