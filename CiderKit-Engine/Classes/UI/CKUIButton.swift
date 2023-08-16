import SpriteKit
import CiderCSSKit

public final class CKUIButton : CKUIContainer, CKUILabelControl {
    
    private static let hoverPseudoClass = "hover"
    private static let activePseudoClass = "active"
    
    internal var label: SKLabelNode!
    
    public let clicked = ParameterlessEventEmitter<CKUIButton>()
    
    public override var isUserInteractionEnabled: Bool { get { true } set { } }
    
    public override var frame: CGRect {
        var frame = super.frame
        let labelFrame = label.frame
        let pivot = self.pivot
        let padding = self.padding
        
        if frame.width == 0 {
            let horizontalPadding = padding.left + padding.right
            frame.size.width = labelFrame.width + horizontalPadding
            let leftPart = frame.size.width * pivot.x
            frame.origin.x -= leftPart
        }
        
        if frame.height == 0 {
            let verticalPadding = padding.bottom + padding.top
            frame.size.height = labelFrame.height + verticalPadding
            let bottomPart = frame.size.height * pivot.y
            frame.origin.y -= bottomPart
        }
        
        return frame
    }
    
    public init(text: String, identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        super.init(type: "button", identifier: identifier, classes: classes, style: style)
        
        label = Self.initLabel(text: text)
        addChild(label)
        
        #if os(macOS)
        TrackingAreaManager.register(node: self)
        #endif
    }
    
    override init(xmlElement: XMLElement) {
        super.init(xmlElement: xmlElement)
        
        let text = xmlElement.getDataPropertyValue(forName: "text")?.stringValue ?? ""
        label = Self.initLabel(text: text)
        addChild(label)
        
        #if os(macOS)
        TrackingAreaManager.register(node: self)
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
        
        label.position = CGPoint(
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
            clicked.notify(from: self)
        }
        else {
            remove(pseudoClass: Self.hoverPseudoClass)
        }
    }
    #else
    public override func touchesBegan(with event: NSEvent) {
        add(pseudoClass: Self.hoverPseudoClass)
        add(pseudoClass: Self.activePseudoClass)
    }
    
    public override func touchesEnded(with event: NSEvent) {
        remove(pseudoClass: Self.activePseudoClass)
        remove(pseudoClass: Self.hoverPseudoClass)
        guard let touch = touches.first else { return }
        let eventPoint = event.location(in: parent!)
        if frame.contains(eventPoint) {
            clicked.notify(from: self)
        }
    }
    #endif
    
}
