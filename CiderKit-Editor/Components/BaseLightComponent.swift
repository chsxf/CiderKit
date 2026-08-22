import CiderKit_Engine
import GameplayKit

protocol BaseLightComponent {

    associatedtype LightType: LightImplementation

    var lightImplementation: LightType { get }

}

extension BaseLightComponent where Self: GKComponent & Selectable {

    func erase() async {
        await MapModel.shared.remove(light: lightImplementation.description)
    }

}
