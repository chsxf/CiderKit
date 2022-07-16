import SpriteKit
import CiderKit_Engine

class SpriteAssetDescriptionScene: SKScene {
    
    private static let defaultSize: CGFloat = 320
    
    override init() {
        super.init(size: CGSize(width: 320, height: 320))
        
        scaleMode = .aspectFill
        
        let gridTexture = Atlases["grid"]!["grid_tile_Base"]!
        
        let sprite = SKSpriteNode(texture: gridTexture)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        sprite.position = CGPoint(x: 0, y: -Int(gridTexture.size().height / 2))
        addChild(sprite)
        
        let camera = SKCameraNode()
        self.camera = camera
        addChild(camera)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setZoomFactor(_ zoomFactor: Int) {
        let newDimension = Self.defaultSize / CGFloat(zoomFactor)
        size = CGSize(width: newDimension, height: newDimension)
    }
    
}
