import simd

public struct AssetBoundingBox {
    
    public var min: SIMD3<Float>
    public var max: SIMD3<Float>
    
    public var size: SIMD3<Float> { max - min }
    
    init(center: SIMD3<Float>, extent: SIMD3<Float>) {
        self.init(min: center - extent, max: center + extent)
    }
        
    init(min: SIMD3<Float>, max: SIMD3<Float>) {
        self.min = min
        self.max = max
    }
    
    init(min: SIMD3<Float>, size: SIMD3<Float>) {
        self.min = min
        max = self.min + size
    }
    
    public mutating func encapsulate(other box: Self) {
        min = simd_min(min, box.min)
        max = simd_max(max, box.max)
    }
    
    public func encapsulating(other box: Self) -> Self {
        var newBox = self
        newBox.encapsulate(other: box)
        return newBox
    }
    
}
