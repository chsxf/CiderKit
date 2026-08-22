public protocol UpdatableObject: AnyObject {

    var updated: AsyncStream<Void> { get }

    func notifyUpdate()

}
