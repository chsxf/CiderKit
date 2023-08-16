import Foundation

fileprivate let dispatchQueue = DispatchQueue(label: "dev.chsxf.ciderkit.eventEmitter")

public final class EventEmitter<T, E> {
    
    public typealias Callback = (_: T, _: E?) -> Void
    
    public class EventEmitterEntry {
        private let callback: Callback
        private let usageLimit: UInt
        private var usage: UInt = 0
        
        init(_ callback: @escaping Callback, usageLimit: UInt) {
            self.callback = callback
            self.usageLimit = usageLimit
        }
        
        fileprivate func use() -> Callback {
            if usageLimit > 0 {
                usage += 1
            }
            return callback
        }
        
        fileprivate var isUsable: Bool {
            return usageLimit == 0 || usageLimit > usage
        }
    }
    
    private var listeners: [EventEmitterEntry] = []
    
    @discardableResult public func on(_ callback: @escaping Callback, usageLimit: UInt = 0) -> EventEmitterEntry {
        let entry = EventEmitterEntry(callback, usageLimit: usageLimit)
        dispatchQueue.sync {
            listeners.append(entry)
        }
        return entry
    }
    
    @discardableResult public func once(_ callback: @escaping Callback) -> EventEmitterEntry {
        return on(callback, usageLimit: 1)
    }
    
    public func notify(_ parameters: T, from sender: E? = nil) -> Void {
        var toCall: [Callback] = []
        
        dispatchQueue.sync {
            for listener in listeners {
                toCall.append(listener.use())
            }
        }
        
        for callback in toCall {
            callback(parameters, sender)
        }
    }
    
}

public final class ParameterlessEventEmitter<E> {
    
    public typealias Callback = (_: E?) -> Void
    
    public class EventEmitterEntry {
        private let callback: Callback
        private let usageLimit: UInt
        private var usage: UInt = 0
        
        init(_ callback: @escaping Callback, usageLimit: UInt) {
            self.callback = callback
            self.usageLimit = usageLimit
        }
        
        fileprivate func use() -> Callback {
            if usageLimit > 0 {
                usage += 1
            }
            return callback
        }
        
        fileprivate var isUsable: Bool {
            return usageLimit == 0 || usageLimit > usage
        }
    }
    
    private var listeners: [EventEmitterEntry] = []
    
    @discardableResult public func on(_ callback: @escaping Callback, usageLimit: UInt = 0) -> EventEmitterEntry {
        let entry = EventEmitterEntry(callback, usageLimit: usageLimit)
        dispatchQueue.sync {
            listeners.append(entry)
        }
        return entry
    }
    
    @discardableResult public func once(_ callback: @escaping Callback) -> EventEmitterEntry {
        return on(callback, usageLimit: 1)
    }
    
    public func notify(from sender: E? = nil) -> Void {
        var toCall: [Callback] = []
        
        dispatchQueue.sync {
            for listener in listeners {
                toCall.append(listener.use())
            }
            listeners = listeners.filter { $0.isUsable }
        }
        
        for callback in toCall {
            callback(sender)
        }
    }
    
}
