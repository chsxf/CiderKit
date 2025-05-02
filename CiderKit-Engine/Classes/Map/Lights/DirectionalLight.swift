import SpriteKit

public class DirectionalLight: BaseLight, NamedObject {

    @Published public var enabled: Bool
    @Published public var name: String
    @Published public var position: WorldPosition
    @Published public var orientation: SIMD2<Float> // declination, right ascension

    public override var type: String { "directional" }

    public override var matrix: matrix_float3x3 {
        get {
            let declinationQuaternion = simd_quatf(angle: -orientation.x, axis: SIMD3(0, 1, 0))
            let rightAscensionQuaternion = simd_quatf(angle: orientation.y, axis: SIMD3(0, 0, 1))

            var direction = SIMD3<Float>(1, 0, 0)
            direction = declinationQuaternion.act(direction)
            direction = rightAscensionQuaternion.act(direction)
            
            return matrix_float3x3([colorVector, direction, SIMD3(0, enabled ? 1 : 0, 0)])
        }
    }

    public init(name: String, color: CGColor, position: SIMD3<Float>, orientation: SIMD2<Float>) {
        enabled = true
        self.name = name
        self.position = position
        self.orientation = orientation
        super.init(color: color)
    }

    public required init(from container: KeyedDecodingContainer<CodingKeys>) throws {
        enabled = try container.decode(Bool.self, forKey: .enabled)
        name = try container.decode(String.self, forKey: .name)

        position = try container.decode(WorldPosition.self, forKey: .position)
        orientation = try container.decode(SIMD2<Float>.self, forKey: .orientation)

        try super.init(from: container)
    }

    public override func encode(to encoder: any Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(enabled, forKey: .enabled)
        try container.encode(name, forKey: .name)

        try container.encode(position, forKey: .position)
        try container.encode(orientation, forKey: .orientation)
    }

}
