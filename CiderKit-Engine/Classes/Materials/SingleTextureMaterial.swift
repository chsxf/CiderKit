import SpriteKit

open class SingleTextureMaterial: BaseMaterial {
    
    enum CodingKeys: String {
        case atlas
        case sprite
    }
    
    public let texture: SKTexture
    
    public init(texture: SKTexture, shader: SKShader) {
        self.texture = texture
        super.init(shader: shader)
    }
    
    required public init(dataContainer: KeyedDecodingContainer<StringCodingKey>) throws {
        let atlasKey = StringCodingKey(stringValue: CodingKeys.atlas.rawValue)!
        let atlasName = try dataContainer.decode(String.self, forKey: atlasKey)
        let atlas = Atlases[atlasName]!
        
        let spriteKey = StringCodingKey(stringValue: CodingKeys.sprite.rawValue)!
        let spriteName = try dataContainer.decode(String.self, forKey: spriteKey)
        self.texture = atlas[spriteName]!
    
        super.init(shader: CiderKitEngine.instantianteUberShader(for: atlas))
    }
    
    open override func clone(withOverrides overrides: CustomSettings?) -> BaseMaterial {
        SingleTextureMaterial(texture: texture, shader: shader)
    }
    
    public override func toSKAction() -> SKAction {
        SKAction.setTexture(texture, resize: true)
    }
    
}
