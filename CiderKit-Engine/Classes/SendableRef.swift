@dynamicMemberLookup
public final class SendableRef<T: Sendable>: Sendable {

    public let ref: T

    public init(_ ref: T) {
        self.ref = ref
    }

    public subscript<TResult>(dynamicMember member: KeyPath<T, TResult>) -> TResult {
        ref[keyPath: member]
    }
}
