import simd

public enum LightImplementationErrors: Error {
    case invalidCast(from: String, to: String)
}

public protocol LightImplementation: UpdatableObject {

    associatedtype Description: LightDescriptor
    
    var description: Description { get }
    var matrix: matrix_float3x3 { get }

    init(from description: Description)
    
    func match(genericDescription: any LightDescriptor) throws -> Bool
    func match(description: Description)
    func reset()

}

public extension LightImplementation {

    var colorVector: SIMD3<Float> { description.colorComponents }

    func match(genericDescription: any LightDescriptor) throws -> Bool {
        guard genericDescription.id != description.id || genericDescription.version != description.version else {
            return false
        }

        guard let castDescription = genericDescription as? Description else {
            throw LightImplementationErrors.invalidCast(from: "\(type(of: genericDescription))", to: "\(Description.Type.self)")
        }

        match(description: castDescription)
        notifyUpdate()
        return true
    }

}
