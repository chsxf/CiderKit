import simd

public struct AssetBoundingBox {
    
    public var min: WorldPosition
    public var max: WorldPosition

    public var size: WorldPosition { max - min }

    init(center: WorldPosition, extent: WorldPosition) {
        self.init(min: center - extent, max: center + extent)
    }
        
    init(min: WorldPosition, max: WorldPosition) {
        self.min = min
        self.max = max
    }
    
    init(min: WorldPosition, size: WorldPosition) {
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
