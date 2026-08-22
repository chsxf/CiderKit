@MainActor
public class LightingImplementation {

    private typealias LightEventStream = (stream: AsyncStream<any LightImplementation>, continuation: AsyncStream<any LightImplementation>.Continuation)

    public private(set) var ambientLight = AmbientLight()
    public private(set) var lights: [any LightImplementation] = []

    private var lightAddedStreams = [LightEventStream]()
    public var lightAdded: AsyncStream<any LightImplementation> { makeEventStream(&lightAddedStreams) }

    private var lightUpdatedStreams = [LightEventStream]()
    public var lightUpdated: AsyncStream<any LightImplementation> { makeEventStream(&lightUpdatedStreams) }

    private var lightRemovedStreams = [LightEventStream]()
    public var lightRemoved: AsyncStream<any LightImplementation> { makeEventStream(&lightRemovedStreams) }

    deinit {
        lightAddedStreams.forEach { $0.continuation.finish() }
        lightRemovedStreams.forEach { $0.continuation.finish() }
    }

    func match(description: LightingDescription) throws {
        ambientLight.match(description: description.ambientLight)

        for i in stride(from: lights.count - 1, through: 0, by: -1) {
            let existingLight = lights[i]
            if !description.lights.contains(where: { $0.id == existingLight.description.id }) {
                lights.remove(at: i)
                notify(lightRemovedStreams, with: existingLight)
            }
        }

        for lightDescription in description.lights {
            if let existingLight = lights.first(where: { $0.description.id == lightDescription.id }) {
                if try existingLight.match(genericDescription: lightDescription) {
                    notify(lightUpdatedStreams, with: existingLight)
                }
            }
            else {
                let newLight = lightDescription.toImplementation()
                lights.append(newLight)
                notify(lightAddedStreams, with: newLight)
            }
        }
    }

    private func makeEventStream(_ array: inout [LightEventStream]) -> AsyncStream<any LightImplementation> {
        let streamData = AsyncStream<any LightImplementation>.makeStream(bufferingPolicy: .unbounded)
        array.append(streamData)
        return streamData.stream
    }

    private func notify(_ array: [LightEventStream], with implementation: any LightImplementation) {
        array.forEach { $0.continuation.yield(implementation) }
    }

}
