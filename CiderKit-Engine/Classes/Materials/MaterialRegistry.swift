public enum MaterialsError: Error {
    case alreadyExisting
    case notRegistered
}

public final actor MaterialRegistry {

    public static let shared = MaterialRegistry()

    private static var materials: [String: BaseMaterial] = [:]

    public static func register(from description: MaterialRegistryDescription) throws {
        for materialDescriptorData in description.materialDescriptorDataList {
            let materialDescription = try MaterialDescriptorFactory.instantiateDescriptor(named: materialDescriptorData.descriptorTypeName, from: materialDescriptorData.dataContainer)
            let material = try materialDescription.material()
            try register(material: material, forName: materialDescriptorData.materialName)
        }
    }
    
    public static func register(material: BaseMaterial, forName name: String) throws {
        if materials[name] != nil {
            throw MaterialsError.alreadyExisting
        }

        materials[name] = material
    }

    public static func material(named name: String, withOverrides overrides: CustomSettings?) throws -> BaseMaterial {
        guard let material = materials[name] else {
            throw MaterialsError.notRegistered
        }
        return material.clone(withOverrides: overrides)
    }

}
