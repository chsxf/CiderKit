import Foundation
import SpriteKit

open class BaseMaterial {
    
    public static let actionKey: String = "material"
    
    public let shader: SKShader
    
    public init(shader: SKShader) {
        self.shader = shader
    }
    
    required public init(dataContainer: KeyedDecodingContainer<StringCodingKey>) throws {
        shader = SKShader()
    }
    
    open func reset() { }
    
    open func clone(withOverrides overrides: CustomSettings?) -> BaseMaterial {
        return BaseMaterial(shader: shader)
    }

    @MainActor
    public final func applyOn(spriteNode: SKSpriteNode, withLocalOverrides localOverrides: CustomSettings?) {
        spriteNode.shader = shader
        spriteNode.run(toSKAction())
    }
    
    public func toSKAction() -> SKAction { SKAction(named: Self.actionKey)! }
    
}
