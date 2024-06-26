import CiderKit_Engine
import CoreGraphics

protocol AssetElementViewDelegate: AnyObject {
    
    func getCurrentAnimationKey(trackType: AssetAnimationTrackType, for elementUUID: UUID) -> AssetAnimationKey?
    func update(element: TransformAssetElement)
    
    func elementView(_ view: TransformAssetElementView, assetWFootprintChanged footprint: Int)
    func elementView(_ view: TransformAssetElementView, assetHFootprintChanged footprint: Int)
    
    func elementView(_ view: TransformAssetElementView, nameChanged newName: String)
    
}
