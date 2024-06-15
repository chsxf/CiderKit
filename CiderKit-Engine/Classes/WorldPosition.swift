import simd

public typealias WorldPosition = SIMD3<Float>

public extension SIMD3<Float> {

    var mapPosition: MapPosition {
        let integralX = Int(x)
        let fractionX = x.truncatingRemainder(dividingBy: 1)
        let integralY = Int(y)
        let fractionY = y.truncatingRemainder(dividingBy: 1)
        let integralElevation = Int(z)
        let fractionZ = z.truncatingRemainder(dividingBy: 1)
        return MapPosition(x: integralX, y: integralY, elevation: integralElevation, worldOffset: WorldPosition(fractionX, fractionY, fractionZ))
    }

    var scenePosition: ScenePosition { MapNode.worldToScene(self) }

}
