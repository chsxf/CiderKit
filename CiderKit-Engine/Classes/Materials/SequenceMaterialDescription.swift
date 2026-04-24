import SpriteKit

public struct SequenceMaterialDescription: MaterialDescriptor {

    public enum CodingKeys: String, CodingKey {
        case frameDuration
        case atlas
        case sprites
    }

    public let frameDuration: TimeInterval
    public let atlasName: String
    public let spriteTextureNames: [String]

    public init(from dataContainer: KeyedDecodingContainer<StringCodingKey>) throws {
        let durationKey = StringCodingKey(codingKey: CodingKeys.frameDuration)!
        self.frameDuration = try dataContainer.decode(TimeInterval.self, forKey: durationKey)

        let atlasKey = StringCodingKey(codingKey: CodingKeys.atlas)!
        self.atlasName = try dataContainer.decode(String.self, forKey: atlasKey)

        let spritesKey = StringCodingKey(codingKey: CodingKeys.sprites)!
        var spriteListContainer = try dataContainer.nestedUnkeyedContainer(forKey: spritesKey)
        var spriteTextureNames = [String]()
        while !spriteListContainer.isAtEnd {
            let textureName = try spriteListContainer.decode(String.self)
            spriteTextureNames.append(textureName)
        }
        self.spriteTextureNames = spriteTextureNames
    }

    public func material() throws -> BaseMaterial {
        let atlas = try Atlases[atlasName]
        let shader = CiderKitEngine.instantianteUberShader(for: atlas)

        var sprites = [SKTexture]()
        for spriteName in spriteTextureNames {
            sprites.append(try atlas[spriteName])
        }

        return SequenceMaterial(sprites: sprites, frameDuration: frameDuration, shader: shader)
    }

}
