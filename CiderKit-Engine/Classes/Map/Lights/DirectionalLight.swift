import SpriteKit

public class DirectionalLight: BaseLightImplementation<DirectionalLightDescription>, NamedObject {
    
    public var enabled: Bool { description.enabled }
    public var name: String { description.name }
    public var position: WorldPosition { description.position }
    public var orientation: SIMD2<Float> { description.orientation }

    public func rename(_ newName: String) async {
        let previousDescriptionVersion = description.version
        let newDescription = description.mutated(withName: newName)
        if previousDescriptionVersion != newDescription.version {
            await MapModel.shared.update(light: newDescription)
        }
    }

    public override var matrix: matrix_float3x3 {
        let declinationQuaternion = simd_quatf(angle: -description.orientation.x, axis: SIMD3(0, 1, 0))
        let rightAscensionQuaternion = simd_quatf(angle: description.orientation.y, axis: SIMD3(0, 0, 1))

        var direction = SIMD3<Float>(1, 0, 0)
        direction = declinationQuaternion.act(direction)
        direction = rightAscensionQuaternion.act(direction)
        
        return matrix_float3x3([description.colorComponents, direction, SIMD3(0, description.enabled ? 1 : 0, 0)])
    }
    
}
