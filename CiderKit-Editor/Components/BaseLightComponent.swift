import CiderKit_Engine

protocol BaseLightComponent {

    associatedtype LightType: LightImplementation

    var lightImplementation: LightType { get }

}
