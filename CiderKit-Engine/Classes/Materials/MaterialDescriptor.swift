import SpriteKit

public protocol MaterialDescriptor: Sendable {

    init(from dataContainer: KeyedDecodingContainer<StringCodingKey>) throws

    @MainActor func material() throws -> BaseMaterial

}
