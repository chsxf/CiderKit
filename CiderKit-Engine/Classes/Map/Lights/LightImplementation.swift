import simd

public enum LightImplementationErrors: Error {
    case invalidCast(from: String, to: String)
}

public protocol LightImplementation: AnyObject {
    
    associatedtype Description: LightDescriptor
    
    var description: Description { get }
    var matrix: matrix_float3x3 { get }

    init(from description: Description)
    
    func match(genericDescription: any LightDescriptor) throws
    func match(description: Description)
    func reset()

}

public extension LightImplementation {

    var colorVector: SIMD3<Float> { description.colorComponents }

    func match(genericDescription: any LightDescriptor) throws {
        guard let castDescription = genericDescription as? Description else {
            throw LightImplementationErrors.invalidCast(from: "\(type(of: genericDescription))", to: "\(Description.Type.self)")
        }
        match(description: castDescription)
    }

}
