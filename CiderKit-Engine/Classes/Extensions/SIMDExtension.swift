import Foundation
import CoreGraphics
import simd

extension SIMD2 {

    public mutating func flip() {
        let buffer = self.y
        self.y = self.x
        self.x = buffer
    }

    public func flipped() -> SIMD2 {
        SIMD2(self.y, self.x)
    }

}

extension SIMD2<Float> {

    public func toCGPoint() -> CGPoint { CGPoint(x: CGFloat(self.x), y: CGFloat(self.y)) }

}

extension SIMD3 {
    
    public init(_ vector: SIMD4<Scalar>) {
        self.init(vector.x, vector.y, vector.z)
    }
    
}

extension SIMD3<Float> {

    public init(_ vector: SIMD2<Float>) {
        self.init(vector.x, vector.y, 0)
    }

    // From: https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
    public init(quaternion: simd_quatf) {
        let q = quaternion.vector

        let sinr_cosp = 2.0 * (q.w * q.x + q.y * q.z)
        let cosr_cosp = 1.0 - 2.0 * (q.x * q.x + q.y * q.y)
        let x = atan2(sinr_cosp, cosr_cosp)

        let sinp = sqrt(1.0 + 2.0 * (q.w * q.y - q.x * q.z))
        let cosp = sqrt(1.0 - 2.0 * (q.w * q.y - q.x * q.z))
        let y = 2.0 * atan2(sinp, cosp) - .pi / 2.0

        let siny_cosp = 2.0 * (q.w * q.z + q.x * q.y)
        let cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)
        let z = atan2(siny_cosp, cosy_cosp)

        self.init(x, y, z)
    }

    public func toQuaternion() -> simd_quatf { simd_quatf(eulerAngles: self) }

}

extension SIMD4 {

    public init(_ vector: SIMD3<Scalar>, _ scalar: Scalar) {
        self.init(vector.x, vector.y, vector.z, scalar)
    }

}

extension simd_quatf {

    // From: https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
    public init(eulerAngles: SIMD3<Float>) {
        let cr = cos(eulerAngles.x * 0.5)
        let sr = sin(eulerAngles.x * 0.5)
        let cp = cos(eulerAngles.y * 0.5)
        let sp = sin(eulerAngles.y * 0.5)
        let cy = cos(eulerAngles.z * 0.5)
        let sy = sin(eulerAngles.z * 0.5)

        let w = cr * cp * cy + sr * sp * sy
        let x = sr * cp * cy - cr * sp * sy
        let y = cr * sp * cy + sr * cp * sy
        let z = cr * cp * sy - sr * sp * cy
        self.init(ix: x, iy: y, iz: z, r: w)
    }

    public func toEulerAngles() -> SIMD3<Float> { SIMD3(quaternion: self) }

}
