import Combine
import Foundation

extension ObservableObject {
    
    func delayed(_ delay: TimeInterval = 1.0) -> DelayedObservableObject<Self> {
        return .init(object: self, delay: delay)
    }
    
}

@dynamicMemberLookup
class DelayedObservableObject<Object>: ObservableObject where Object: ObservableObject {
    
    private var original: Object
    private var subscription: AnyCancellable?
    
    fileprivate init(object: Object, delay: TimeInterval) {
        self.original = object
        subscription = object.objectWillChange
            .throttle(for: RunLoop.SchedulerTimeType.Stride(delay), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }
    
    subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Object, Subject>) -> Subject {
        get { original[keyPath: keyPath] }
        set { original[keyPath: keyPath] = newValue }
    }
    
}
