import os

@dynamicMemberLookup
public final class SendableMutableRef<T: Sendable>: Sendable {

    private let refLock: OSAllocatedUnfairLock<T>

    public var ref: T {
        get { refLock.withLock { $0 } }
        set { refLock.withLock { $0 = newValue } }
    }

    public init(_ ref: T) {
        refLock = OSAllocatedUnfairLock(initialState: ref)
    }

    public subscript<TResult>(dynamicMember member: KeyPath<T, TResult>) -> TResult? {
        ref[keyPath: member]
    }

}
