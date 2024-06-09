public struct OverridableValue<ValueType> {

    public var baseValue: ValueType
    public var overriddenValue: ValueType?

    public var currentValue: ValueType { overriddenValue ?? baseValue }

    init(_ baseValue: ValueType) {
        self.baseValue = baseValue
        overriddenValue = nil
    }

}
