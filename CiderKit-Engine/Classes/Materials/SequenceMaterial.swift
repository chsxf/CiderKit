import SpriteKit
import GameplayKit

open class SequenceMaterial: BaseMaterial {
    
    enum CodingKeys: String {
        case frameDuration
        case atlas
        case sprites
    }
    
    public let sprites: [SKTexture]
    public let frameDuration: TimeInterval
    public var firstFrame: Int
    
    public init(sprites: [SKTexture], frameDuration: TimeInterval, shader: SKShader) {
        self.sprites = sprites
        self.frameDuration = frameDuration
        self.firstFrame = 0
        super.init(shader: shader)
    }
    
    required public init(dataContainer: KeyedDecodingContainer<StringCodingKey>) throws {
        firstFrame = 0
        
        let durationKey = StringCodingKey(stringValue: CodingKeys.frameDuration.rawValue)!
        self.frameDuration = try dataContainer.decode(TimeInterval.self, forKey: durationKey)
        
        let atlasKey = StringCodingKey(stringValue: CodingKeys.atlas.rawValue)!
        let atlasName = try dataContainer.decode(String.self, forKey: atlasKey)
        let atlas = Atlases[atlasName]!
        
        let spritesKey = StringCodingKey(stringValue: CodingKeys.sprites.rawValue)!
        var spritesContainer = try dataContainer.nestedUnkeyedContainer(forKey: spritesKey)
        var sprites = [SKTexture]()
        while !spritesContainer.isAtEnd {
            let textureName = try spritesContainer.decode(String.self)
            sprites.append(atlas[textureName]!)
        }
        self.sprites = sprites
        
        super.init(shader: CiderKitEngine.instantianteUberShader(for: atlas))
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
