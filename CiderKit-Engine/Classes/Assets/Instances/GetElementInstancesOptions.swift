public struct GetElementInstancesOptions: OptionSet {

    public let rawValue: Int

    public static let directChildrenOnly = Self.init(rawValue: 1)
    public static let includeNestedReferences = Self.init(rawValue: 2)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

}
