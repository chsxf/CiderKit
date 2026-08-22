import SpriteKit

public protocol LightDescriptor: Encodable, Sendable, Identifiable {
    
    associatedtype Implementation: LightImplementation
    
    var id: UUID { get }
    var type: String { get }
    var color: CGColor { get }
    
    init()
    init(from container: KeyedDecodingContainer<LightDescriptorCodingKeys>) throws
    
    func toImplementation() -> Implementation
    
    func mutated(withColor newColor: CGColor) -> Self
    
}

public extension LightDescriptor {
    
    var colorVector: SIMD3<Float> {
        get {
            let cmpts = color.components!
            return SIMD3(Float(cmpts[0]), Float(cmpts[1]), Float(cmpts[2]))
        }
    }
    
}
