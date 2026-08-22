import Foundation
import SpriteKit

public class PointLight: BaseLight<PointLightDescription>, NamedObject {
    
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

    public var falloff: PointLightDescription.Falloff {
        get { description.falloff }
        set { description = description.mutated(withFalloff: newValue) }
    }

    public override var matrix: matrix_float3x3 {
        var falloffVector = description.falloff.vector
        if !description.enabled {
            falloffVector.y = 0
        }
        return matrix_float3x3([description.colorComponents, description.position, falloffVector])
    }
    
    public subscript(dynamicMember member: KeyPath<PointLightDescription, PointLightDescription.Falloff>) -> PointLightDescription.Falloff {
        description[keyPath: member]
    }
    
}
