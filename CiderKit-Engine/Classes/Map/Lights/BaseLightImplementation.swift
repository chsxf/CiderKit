import Foundation
import SpriteKit

public class BaseLightImplementation<T: LightDescriptor>: LightImplementation {

    typealias LightEventData = (stream: AsyncStream<Void>, continuation: AsyncStream<Void>.Continuation)

    public var description: T
    open var matrix: matrix_float3x3 { fatalError("Missing implementation") }

    private var updateStreams = [LightEventData]()
    public var updated: AsyncStream<Void> { Self.makeStream(streamArray: &updateStreams) }

    public var id: UUID { description.id }
    public var color: CGColor { description.color }

    public required convenience init() {
        self.init(from: T())
    }
    
    public required init(from description: T) {
        self.description = description
    }

    deinit {
        updateStreams.forEach { $0.continuation.finish() }
    }

    open func match(description: T) {
        if self.description.id != description.id || self.description.version != description.version {
            self.description = description
        }
    }
    
    public func reset() {
        self.description = T()
    }

    public func notifyUpdate() {
        Self.notify(streamArray: updateStreams)
    }

    static func makeStream(streamArray: inout [LightEventData]) -> AsyncStream<Void> {
        let eventData = AsyncStream<Void>.makeStream(bufferingPolicy: .unbounded)
        streamArray.append(eventData)
        return eventData.stream
    }

    static func notify(streamArray: [LightEventData]) {
        streamArray.forEach { $0.continuation.yield() }
    }

}
