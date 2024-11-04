public struct OverridableValue<ValueType: Sendable>: Sendable {

    public var baseValue: ValueType
    public var overriddenValue: ValueType?

    public var currentValue: ValueType { overriddenValue ?? baseValue }

    init(_ baseValue: ValueType) {
        self.baseValue = baseValue
        overriddenValue = nil
    }

}
