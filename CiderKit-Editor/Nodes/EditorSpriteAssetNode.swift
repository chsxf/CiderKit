import CiderKit_Engine
import SpriteKit

class EditorSpriteAssetNode: SpriteAssetNode {
    
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
    
    public override init(placement: SpriteAssetPlacement, description: SpriteAssetDescription, at worldPosition: simd_float3) {
        super.init(placement: placement, description: description, at: worldPosition)
        
        outline = SKShapeNode(rect: calculateAccumulatedFrame())
        outline.isHidden = true
        outline.lineWidth = 1
        addChild(outline)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
