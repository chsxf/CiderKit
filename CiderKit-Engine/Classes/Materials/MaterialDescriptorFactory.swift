public enum MaterialDescriptorFactoryErrors: Error {
    case alreadyRegistered
    case notRegistered
    case instantiationFailed
}

public final actor MaterialDescriptorFactory {

    private static var descriptorByTypeName: [String: MaterialDescriptor.Type] = [:]

    public static func registerBuiltinMaterialTypes() {
        if descriptorByTypeName.count == 0 {
            try! registerDescriptorType(SingleTextureMaterialDescription.self, named: "single_texture")
            try! registerDescriptorType(SequenceMaterialDescription.self, named: "sequence")
        }
    }

    public static func registerDescriptorType(_ type: MaterialDescriptor.Type, named typeName: String) throws {
        if let _ = descriptorByTypeName[typeName] {
            throw MaterialDescriptorFactoryErrors.alreadyRegistered
        }
        descriptorByTypeName[typeName] = type
    }

    public static func instantiateDescriptor(named typeName: String, from dataContainer: KeyedDecodingContainer<StringCodingKey>) throws -> any MaterialDescriptor {
        registerBuiltinMaterialTypes()

        guard let descriptorType = descriptorByTypeName[typeName] else {
            throw MaterialDescriptorFactoryErrors.notRegistered
        }

        do {
            return try descriptorType.init(from: dataContainer)
        }
        catch {
            throw MaterialDescriptorFactoryErrors.instantiationFailed
        }
    }

}
