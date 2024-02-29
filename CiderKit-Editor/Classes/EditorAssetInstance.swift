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
        self.init(placement: AssetPlacement(assetLocator: assetDescription.locator), at: SIMD3(), offsetNodeByWorldPosition: true)!
    }
    
    override init?(placement: AssetPlacement, at worldPosition: SIMD3<Float>, offsetNodeByWorldPosition: Bool = true) {
        super.init(placement: placement, at: worldPosition, offsetNodeByWorldPosition: offsetNodeByWorldPosition)!
        
        if let node {
            outline = SKShapeNode(rect: node.calculateAccumulatedFrame())
            outline.position = CGPoint(x: -node.position.x, y: -node.position.y)
            outline.isHidden = true
            outline.lineWidth = 1
            node.addChild(outline)
        }
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
    
}
