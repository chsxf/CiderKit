import SpriteKit
import CoreGraphics
import CiderCSSKit

open class CKUIContainer : CKUIBaseNode {
    
    private let backgroundImage: SKSpriteNode
    
    private var borderImageURL: URL? = nil
    
    public required init(type: String = "container", identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil, customData: [String: any Sendable]? = nil) {
        backgroundImage = SKSpriteNode(texture: nil, color: SKColor.white, size: CGSize())
        backgroundImage.zPosition = -1
        
        super.init(type: type, identifier: identifier, classes: classes, style: style, customData: customData)
        
        zPosition = 2

        addChild(backgroundImage)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override class func parseCustomData(_ customData: [String : String]) throws -> [String : any Sendable] {
        try super.parseCustomData(customData)
    }

    open override func updateLayout() {
        super.updateLayout()
        
        guard parent != nil else { return }
        
        let pos = position
        let localFrame = frame.offsetBy(dx: -pos.x, dy: -pos.y)

        backgroundImage.anchorPoint = CGPoint()
        backgroundImage.size = localFrame.size
        backgroundImage.position = localFrame.origin
            
        var showImage: Bool = false
        
        if let borderImageSource = getStyleValue(key: CSSAttributes.borderImageSource), case let CSSValue.url(borderImageSourceURL) = borderImageSource {
            let texture = CKUIURLResolver.resolveTexture(url: borderImageSourceURL)
            backgroundImage.texture = texture
            
            let textureSize = texture.size()
            
            let borderImageSlice = getStyleValues(key: CSSAttributes.borderImageSlice)!
            var slices = [CGFloat](repeating: 0, count: 4)
            for i in 0..<slices.count {
                switch borderImageSlice[i] {
                case let .number(number):
                    slices[i] = CGFloat(number)
                    break
                    
                case let .percentage(percent):
                    let naturalPercent = percent / 100
                    if i % 2 == 0 {
                        slices[i] = textureSize.height * naturalPercent
                    }
                    else {
                        slices[i] = textureSize.width * naturalPercent
                    }
                    break
                    
                default:
                    break
                }
            }
            
            let rect = CGRect(
                x: slices[1] / textureSize.width,
                y: slices[0] / textureSize.height,
                width: (textureSize.width - slices[3] - slices[1]) / textureSize.width,
                height: (textureSize.height - slices[2] - slices[0]) / textureSize.height
            )
            backgroundImage.centerRect = rect
            
            showImage = true
        }
        else {
            backgroundImage.texture = nil
            backgroundImage.centerRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        
        if let backgroundColor = getStyleColor(key: CSSAttributes.backgroundColor) {
            backgroundImage.color = backgroundColor
            backgroundImage.colorBlendFactor = 1
            showImage = true
        }
        else {
            backgroundImage.colorBlendFactor = 0
        }
        
        backgroundImage.isHidden = !showImage
    }
    
}
