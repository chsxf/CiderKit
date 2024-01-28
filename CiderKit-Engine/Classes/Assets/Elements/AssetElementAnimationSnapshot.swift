public struct AssetElementAnimationSnapshot {
    
    public let frame: UInt
    public let element: TransformAssetElement
    public let animatedValues: [AssetAnimationTrackType: Any]
    
    public subscript(trackType: AssetAnimationTrackType) -> Any? {
        animatedValues[trackType] ?? element[trackType]
    }
    
    public func get<T>(trackType: AssetAnimationTrackType) -> T {
        let trackTypeValue = self[trackType]
        
        if T.self == CGFloat.self && trackTypeValue is Float {
            return CGFloat(trackTypeValue as! Float) as! T
        }
        
        if T.self == Float.self && trackTypeValue is CGFloat {
            return Float(trackTypeValue as! CGFloat) as! T
        }
        
        return trackTypeValue as! T
    }
    
}
