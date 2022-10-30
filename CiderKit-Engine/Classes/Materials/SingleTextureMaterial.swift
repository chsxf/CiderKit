import SpriteKit

open class SingleTextureMaterial: BaseMaterial {
    
    public let texture: SKTexture
    
    public init(texture: SKTexture, shader: SKShader) {
        self.texture = texture

        super.init(shader: shader)
    }
    
    open override func clone(withOverrides overrides: CustomSettings?) -> BaseMaterial {
        SingleTextureMaterial(texture: texture, shader: shader)
    }
    
    public override func toSKAction() -> SKAction {
        SKAction.setTexture(texture, resize: true)
    }
    
}
