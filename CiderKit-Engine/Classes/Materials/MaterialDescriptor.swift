import SpriteKit

public protocol MaterialDescriptor: Sendable {

    init(from dataContainer: KeyedDecodingContainer<StringCodingKey>) throws

    func material() throws -> BaseMaterial

}
