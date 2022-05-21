import Foundation

open class Pool<Element> where Element: Equatable {
    
    private var available: [Element] = [Element]()
    private var used: [Element] = [Element]()
    
    private let deallocationClosure: (Element) -> Void
    
    public init(deallocation: @escaping (Element) -> Void) {
        deallocationClosure = deallocation
    }
    
    public func hasAvailability() -> Bool {
        return !available.isEmpty
    }
    
    public func getElement() -> Element? {
        if hasAvailability() {
            let element = available.popLast()!
            used.append(element)
            return element
        }
        return nil
    }
    
    public func returnElement(_ element: Element) {
        if used.contains(element) {
            used.removeAll { $0 == element }
            deallocationClosure(element)
        }
        if !available.contains(element) {
            available.append(element)
        }
    }
    
    public func returnAll() {
        used.forEach(deallocationClosure)
        available.append(contentsOf: used)
        used.removeAll()
    }
    
}
