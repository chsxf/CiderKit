import SpriteKit
import CiderCSSKit
import Combine

public final class CKUIButton : CKUIContainer, CKUILabelControl {
    
    private static let hoverPseudoClass = "hover"
    private static let activePseudoClass = "active"
    
    internal var label: SKLabelNode? = nil
    internal var sprite: SKSpriteNode? = nil
    
    public let clicked = PassthroughSubject<CKUIButton, Never>()

    public override var isUserInteractionEnabled: Bool { get { true } set { } }
    
    public override var frame: CGRect {
        var frame = super.frame
        let pivot = self.pivot
        let padding = self.padding
        
        let contentFrame = label?.frame ?? sprite!.frame
                
        if frame.width == 0 {
            let horizontalPadding = padding.left + padding.right
            frame.size.width = contentFrame.width + horizontalPadding
            let leftPart = frame.size.width * pivot.x
            frame.origin.x -= leftPart
        }
        
        if frame.height == 0 {
            let verticalPadding = padding.bottom + padding.top
            frame.size.height = contentFrame.height + verticalPadding
            let bottomPart = frame.size.height * pivot.y
            frame.origin.y -= bottomPart
        }
        
        return frame
    }
    
    public convenience init(text: String, identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        self.init(identifier: identifier, classes: classes, style: style, customData: ["text": text])
    }
    
    public convenience init(image: SKTexture, identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        self.init(identifier: identifier, classes: classes, style: style, customData: ["image": image])
    }
    
    public convenience init(imageOf url: URL, identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        let texture = CKUIURLResolver.resolveTexture(url: url)
        self.init(identifier: identifier, classes: classes, style: style, customData: ["image": texture])
    }
    
    public required init(type: String = "button", identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil, customData: [String:Any]? = nil) {
        super.init(type: type, identifier: identifier, classes: classes, style: style, customData: customData)
        
        if let text = customData!["text"] as? String {
            label = Self.initLabel(text: text)
            addChild(label!)
        }
        else if let image = customData!["image"] as? SKTexture {
            sprite = SKSpriteNode(texture: image)
            addChild(sprite!)
        }
        else if let imageURL = customData!["imageURL"] as? String {
            let url = URL(string: imageURL)!
            let image = CKUIURLResolver.resolveTexture(url: url)
            sprite = SKSpriteNode(texture: image)
            addChild(sprite!)
        }
        
        #if os(macOS)
        NotificationCenter.default.post(name: .trackingAreaRegistrationRequested, object: self)
        #endif
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func initLabel(text: String) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.numberOfLines = 1
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.fontSize = 12
        return label
    }
    
    public override func updateLayout() {
        super.updateLayout()
        
        guard parent != nil else { return }
        
        let localFrame = frame.offsetBy(dx: -position.x, dy: -position.y)
        
        updateFontColor()
        updateFontName()
        updateFontSize()
        
        let padding = self.padding
        let horizontalPaddingOffset = (padding.left - padding.right) / 2
        let verticalPaddingOffset = (padding.bottom - padding.top) / 2
        
        let contentNode = label ?? sprite!
        contentNode.position = CGPoint(
            x: localFrame.minX + localFrame.width / 2 + horizontalPaddingOffset,
            y: localFrame.minY + localFrame.height / 2 + verticalPaddingOffset
        )
    }
    
    #if os(macOS)
    public override func mouseEntered(with event: NSEvent) {
        add(pseudoClass: Self.hoverPseudoClass)
    }
    
    public override func mouseExited(with event: NSEvent) {
        remove(pseudoClass: Self.hoverPseudoClass)
    }
    
    public override func mouseDown(with event: NSEvent) {
        add(pseudoClass: Self.activePseudoClass)
    }
    
    public override func mouseUp(with event: NSEvent) {
        remove(pseudoClass: Self.activePseudoClass)
        let eventPoint = event.location(in: parent!)
        if frame.contains(eventPoint) {
            clicked.send(self)
        }
        else {
            remove(pseudoClass: Self.hoverPseudoClass)
        }
    }
    #else
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        add(pseudoClass: Self.hoverPseudoClass)
        add(pseudoClass: Self.activePseudoClass)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        remove(pseudoClass: Self.activePseudoClass)
        remove(pseudoClass: Self.hoverPseudoClass)
        guard let touch = touches.first else { return }
        let eventPoint = touch.location(in: parent!)
        if frame.contains(eventPoint) {
            clicked.send(from: self)
        }
    }
    #endif
    
}
