public struct ResetOverriddenValuesOptions: OptionSet, Sendable {

    public let rawValue: Int

    public static let applyToChildren = Self.init(rawValue: 1)
    public static let applyToNestedReferences = Self.init(rawValue: 2)
    public static let updateImmediately = Self.init(rawValue: 4)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

}
