public struct MaterialRegistryDescription: Decodable {

    enum TopLevelCodingKeys: String, CodingKey {
        case materials
    }

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case data
    }

    public struct MaterialDescriptorData {
        public let materialName: String
        public let descriptorTypeName: String
        public let dataContainer: KeyedDecodingContainer<StringCodingKey>
    }

    public let materialDescriptorDataList: [MaterialDescriptorData]

    public init(from decoder: Decoder) throws {
        let topLevelContainer = try decoder.container(keyedBy: TopLevelCodingKeys.self)

        var materials = try topLevelContainer.nestedUnkeyedContainer(forKey: .materials)
        var materialDescriptorDataList = [MaterialDescriptorData]()
        while !materials.isAtEnd {
            let materialContainer = try materials.nestedContainer(keyedBy: CodingKeys.self)

            let name = try materialContainer.decode(String.self, forKey: .name)
            let type = try materialContainer.decode(String.self, forKey: .type)
            let dataContainer = try materialContainer.nestedContainer(keyedBy: StringCodingKey.self, forKey: .data)

            materialDescriptorDataList.append(MaterialDescriptorData(materialName: name, descriptorTypeName: type, dataContainer: dataContainer))
        }

        self.materialDescriptorDataList = materialDescriptorDataList
    }

}
