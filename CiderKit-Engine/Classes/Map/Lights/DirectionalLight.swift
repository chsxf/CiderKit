import SpriteKit

public class DirectionalLight: BaseLight<DirectionalLightDescription>, NamedObject {
    
    public var enabled: Bool {
        get { description.enabled }
        set { description = description.mutated(withEnabled: newValue) }
    }
    
    public var name: String {
        get { description.name }
        set { description = description.mutated(withName: newValue) }
    }
    
    public var position: WorldPosition {
        get { description.position }
        set { description = description.mutated(withPosition: newValue) }
    }
    
    public var orientation: SIMD2<Float> {
        get { description.orientation }
        set { description = description.mutated(withOrientation: newValue) }
    }
    
    public override var matrix: matrix_float3x3 {
        let declinationQuaternion = simd_quatf(angle: -description.orientation.x, axis: SIMD3(0, 1, 0))
        let rightAscensionQuaternion = simd_quatf(angle: description.orientation.y, axis: SIMD3(0, 0, 1))

        var direction = SIMD3<Float>(1, 0, 0)
        direction = declinationQuaternion.act(direction)
        direction = rightAscensionQuaternion.act(direction)
        
        return matrix_float3x3([description.colorVector, direction, SIMD3(0, description.enabled ? 1 : 0, 0)])
    }
    
}
