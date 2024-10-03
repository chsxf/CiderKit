import simd

public typealias WorldPosition = SIMD3<Float>

public extension SIMD3<Float> {

    var mapPosition: MapPosition {
        let integralX = x.rounded(.down)
        let fractionX = x - integralX
        let integralY = y.rounded(.down)
        let fractionY = y - integralY
        let integralElevation = z.rounded(.towardZero)
        let fractionZ = z - integralElevation
        return MapPosition(x: Int(integralX), y: Int(integralY), elevation: Int(integralElevation), worldOffset: WorldPosition(fractionX, fractionY, fractionZ))
    }

    var unoffsettedMapPosition: MapPosition {
        let mp = mapPosition
        return MapPosition(x: mp.x, y: mp.y, elevation: mp.elevation)
    }

    var scenePosition: ScenePosition { MapNode.worldToScene(self) }

    init(intX x: Int, y: Int, z: Int) {
        self.init(Float(x), Float(y), Float(z))
    }

}
