import simd

public protocol LightImplementation: AnyObject {
    
    associatedtype Description: LightDescriptor
    
    var description: Description { get }
    var matrix: matrix_float3x3 { get }

    init(from description: Description)
    
    func match(description: Description)
    func reset()
    
}

public extension LightImplementation {

    var colorVector: SIMD3<Float> { description.colorComponents }

}
