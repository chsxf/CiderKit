public final actor CKUINodeTypeRegistry {

    fileprivate struct NodeTypeRegistrationData {
        let typeRepresentation: String
        let bundle: Bundle
    }

    fileprivate static var registeredNodeTypes: [String: NodeTypeRegistrationData] = [:]
    fileprivate static var builtinNodeTypesRegistered = false

    public static func registerBuiltinComponents() {
        guard !builtinNodeTypesRegistered else { return }

        try! registerNodeType(CKUIContainer.self, with: "container")
        try! registerNodeType(CKUILabel.self, with: "label")
        try! registerNodeType(CKUIButton.self, with: "button")

        builtinNodeTypesRegistered = true
    }

    public static func registerNodeType<T: CKUIBaseNode>(_ type: T.Type, with name: String, in bundle: Bundle? = nil) throws {
        if registeredNodeTypes[name] != nil {
            throw CKUILoaderErrors.alreadyRegisteredComponentType(name: name)
        }
        registeredNodeTypes[name] = NodeTypeRegistrationData(
            typeRepresentation: String(reflecting: type),
            bundle: bundle ?? CiderKitEngine.bundle
        )
    }

    static func getNodeClass(with name: String) throws -> CKUIBaseNode.Type {
        guard let componentRegistrationData = registeredNodeTypes[name] else {
            throw CKUILoaderErrors.unregisteredComponentType(name: name)
        }

        guard let loadedClass = componentRegistrationData.bundle.classNamed(componentRegistrationData.typeRepresentation) else {
            throw CKUILoaderErrors.componentClassNotFound(className: componentRegistrationData.typeRepresentation)
        }

        guard let castedClass = loadedClass as? CKUIBaseNode.Type else {
            throw CKUILoaderErrors.invalidClassType(className: componentRegistrationData.typeRepresentation)
        }

        return castedClass
    }

}
