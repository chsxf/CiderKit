import CiderKit_Engine
import SpriteKit

final class EditorAssetInstance: AssetInstance {
    
    private var outline: SKShapeNode!
    
    var selected: Bool = false {
        didSet {
            updateOutlineColor()
        }
    }
    
    var hovered: Bool = false {
        didSet {
            updateOutlineColor()
        }
    }
    
    convenience init(assetDescription: AssetDescription) {
        self.init(placement: AssetPlacement(assetLocator: assetDescription.locator), at: SIMD3())!
    }
    
    override init?(placement: AssetPlacement, at worldPosition: SIMD3<Float>) {
        super.init(placement: placement, at: SIMD3())!
        
        outline = SKShapeNode(rect: node!.calculateAccumulatedFrame())
        outline.isHidden = true
        outline.lineWidth = 1
        node!.addChild(outline)
    }
    
    fileprivate func updateOutlineColor() {
        if !selected && !hovered {
            outline.isHidden = true
        }
        else {
            let color = selected ? SKColor.green : SKColor.red
            outline.isHidden = false
            outline.strokeColor = color
        }
    }
    
    func removeElement(element: TransformAssetElement) {
        self[element]?.removeFromParent()
    }
    
}
