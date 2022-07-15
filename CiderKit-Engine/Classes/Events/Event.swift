private protocol Invocable: AnyObject {

    func invoke(data: Any)
    
}

public class Event<T> {

    public typealias EventHandler = (T) -> ()

    private class EventHandle<U: AnyObject> : Disposable, Invocable {
        
        weak var target: U?
        let handler: (U) -> EventHandler
        let event: Event<T>

        init(target: U, handler: @escaping (U) -> EventHandler, event: Event<T>) {
            self.target = target
            self.handler = handler
            self.event = event;
        }

        func invoke(data: Any) -> () {
            if let t = target, let dataAsT = data as? T {
                handler(t)(dataAsT)
            }
        }

        func dispose() {
            event.eventHandles = event.eventHandles.filter { $0 !== self }
        }
        
    }
    
    private var eventHandles = [Invocable]()

    public init() { }
    
    public func raise(_ data: T) {
        for handler in self.eventHandles {
            handler.invoke(data: data)
        }
    }

    public func addListener<U: AnyObject>(target: U, _ handler: @escaping (U) -> EventHandler) -> Disposable {
        let wrapper = EventHandle(target: target, handler: handler, event: self)
        eventHandles.append(wrapper)
        return wrapper
    }
    
}
