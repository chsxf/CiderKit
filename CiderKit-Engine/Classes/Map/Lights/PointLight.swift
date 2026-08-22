import Foundation
import SpriteKit

public class PointLight: BaseLightImplementation<PointLightDescription>, NamedObject {

    public var enabled: Bool { description.enabled }
    public var name: String { description.name }
    public var position: WorldPosition { description.position }
    public var falloff: PointLightDescription.Falloff { description.falloff }

    public func rename(_ newName: String) async {
        let previousDescriptionVersion = description.version
        let newDescription = description.mutated(withName: newName)
        if previousDescriptionVersion != newDescription.version {
            await MapModel.shared.update(light: newDescription)
        }
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
