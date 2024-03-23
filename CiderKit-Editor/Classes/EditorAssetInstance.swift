import CiderKit_Engine
import SpriteKit

final class EditorAssetInstance: AssetInstance {
    
    convenience init(assetDescription: AssetDescription) {
        self.init(placement: AssetPlacement(assetLocator: assetDescription.locator), at: SIMD3(), offsetNodeByWorldPosition: true)!
    }
    
    override init?(placement: AssetPlacement, at worldPosition: SIMD3<Float>, offsetNodeByWorldPosition: Bool = true) {
        super.init(placement: placement, at: worldPosition, offsetNodeByWorldPosition: offsetNodeByWorldPosition)!
    }
    
}
