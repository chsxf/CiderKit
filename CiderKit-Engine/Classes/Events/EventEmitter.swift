import Foundation

fileprivate let dispatchQueue = DispatchQueue(label: "dev.chsxf.ciderkit.eventEmitter")

public final class EventEmitter<T, E> {
    
    public typealias Callback = (_: T, _: E?) -> Void
    
    public class EventEmitterEntry: Equatable {
        fileprivate let uuid = UUID()

        fileprivate let callback: Callback
        fileprivate let usageLimit: UInt
        fileprivate var usage: UInt = 0
        fileprivate weak var emitter: EventEmitter<T, E>?

        fileprivate var isUsable: Bool {
            return usageLimit == 0 || usageLimit > usage
        }

        fileprivate init(_ callback: @escaping Callback, usageLimit: UInt, emitter: EventEmitter<T, E>) {
            self.callback = callback
            self.usageLimit = usageLimit
            self.emitter = emitter
        }

        fileprivate func call(_ parameters: T, from sender: E?) {
            if usageLimit > 0 {
                usage += 1
            }
            callback(parameters, sender)
        }

        public func disconect() {
            emitter?.disconnect(self)
        }

        public static func == (lhs: EventEmitterEntry, rhs: EventEmitterEntry) -> Bool {
            lhs.uuid == rhs.uuid
        }
    }
    
    fileprivate var listeners: [EventEmitterEntry] = []

    @discardableResult
    public func on(_ callback: @escaping Callback, usageLimit: UInt = 0) -> EventEmitterEntry {
        let entry = EventEmitterEntry(callback, usageLimit: usageLimit, emitter: self)
        dispatchQueue.sync {
            listeners.append(entry)
        }
        return entry
    }
    
    @discardableResult
    public func once(_ callback: @escaping Callback) -> EventEmitterEntry {
        on(callback, usageLimit: 1)
    }
    
    public func disconnect(_ eventEntry: EventEmitterEntry) {
        dispatchQueue.sync {
            listeners.removeAll { $0.uuid == eventEntry.uuid }
        }
    }

    public func notify(_ parameters: T, from sender: E? = nil) -> Void {
        var toCall: [EventEmitterEntry] = []

        dispatchQueue.sync {
            toCall.append(contentsOf: listeners.filter { $0.isUsable })
        }
        
        for entry in toCall {
            entry.call(parameters, from: sender)
        }

        dispatchQueue.sync {
            listeners.removeAll { !$0.isUsable }
        }
    }
    
}

public final class ParameterlessEventEmitter<E> {
    
    public typealias Callback = (_: E?) -> Void
    
    public class EventEmitterEntry: Equatable {
        fileprivate let uuid = UUID()

        fileprivate let callback: Callback
        fileprivate let usageLimit: UInt
        fileprivate var usage: UInt = 0
        fileprivate weak var emitter: ParameterlessEventEmitter<E>?

        fileprivate var isUsable: Bool {
            return usageLimit == 0 || usageLimit > usage
        }

        fileprivate init(_ callback: @escaping Callback, usageLimit: UInt, emitter: ParameterlessEventEmitter<E>) {
            self.callback = callback
            self.usageLimit = usageLimit
            self.emitter = emitter
        }
        
        fileprivate func call(from sender: E?) {
            if usageLimit > 0 {
                usage += 1
            }
            callback(sender)
        }

        public func disconnect() {
            emitter?.disconnect(self)
        }

        public static func == (lhs: EventEmitterEntry, rhs: EventEmitterEntry) -> Bool {
            lhs.uuid == rhs.uuid
        }
    }
    
    fileprivate var listeners: [EventEmitterEntry] = []

    @discardableResult
    public func on(_ callback: @escaping Callback, usageLimit: UInt = 0) -> EventEmitterEntry {
        let entry = EventEmitterEntry(callback, usageLimit: usageLimit, emitter: self)
        dispatchQueue.sync {
            listeners.append(entry)
        }
        return entry
    }
    
    @discardableResult
    public func once(_ callback: @escaping Callback) -> EventEmitterEntry {
        on(callback, usageLimit: 1)
    }
    
    public func disconnect(_ eventEntry: EventEmitterEntry) {
        dispatchQueue.sync {
            listeners.removeAll { $0.uuid == eventEntry.uuid }
        }
    }

    public func notify(from sender: E? = nil) -> Void {
        var toCall: [EventEmitterEntry] = []

        dispatchQueue.sync {
            toCall.append(contentsOf: listeners.filter { $0.isUsable })
        }
        
        for entry in toCall {
            entry.call(from: sender)
        }

        dispatchQueue.sync {
            listeners.removeAll { !$0.isUsable }
        }
    }

}
