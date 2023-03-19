import SpriteKit

open class CKUIImage: CKUIBaseNode {
    
    private let image: SKSpriteNode
    
    public init(identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        image = SKSpriteNode(texture: nil, color: SKColor.white, size: CGSize())
        
        super.init(type: "image", identifier: identifier, classes: classes, style: style)
        
        addChild(image)
    }
    
    override init(xmlElement: XMLElement) {
        image = SKSpriteNode(texture: nil, color: SKColor.white, size: CGSize())
        
        super.init(xmlElement: xmlElement)
        
        addChild(image)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func updateLayout() {
        super.updateLayout()
        
        guard parent != nil else { return }
        
        let pos = position
        let localFrame = frame.offsetBy(dx: -pos.x, dy: -pos.y)
        
        image.anchorPoint = CGPoint()
        image.size = localFrame.size
        image.position = localFrame.origin
        image.color = getStyleColor(key: "color")
    }
    
}
