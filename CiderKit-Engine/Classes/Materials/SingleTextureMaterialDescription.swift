public struct SingleTextureMaterialDescription: MaterialDescriptor {

    enum CodingKeys: String, CodingKey {
        case atlas
        case sprite
    }

    public let atlasName: String
    public let spriteName: String

    public init(from dataContainer: KeyedDecodingContainer<StringCodingKey>) throws {
        let atlasKey = StringCodingKey(codingKey: CodingKeys.atlas)!
        self.atlasName = try dataContainer.decode(String.self, forKey: atlasKey)

        let spriteKey = StringCodingKey(codingKey: CodingKeys.sprite)!
        self.spriteName = try dataContainer.decode(String.self, forKey: spriteKey)
    }

    public func material() throws -> BaseMaterial {
        let atlas = try Atlases[atlasName]
        let shader = CiderKitEngine.instantianteUberShader(for: atlas)
        let sprite = try atlas[spriteName]
        return SingleTextureMaterial(texture: sprite, shader: shader)
    }

}
