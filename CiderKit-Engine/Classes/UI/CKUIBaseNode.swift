import SpriteKit
import CiderCSSKit

open class CKUIBaseNode : SKNode, CSSConsumer {
    
    public var styleSheet: CKUIStyleSheet? {
        guard let parentUINode = parent as? CKUIBaseNode else { return nil }
        return parentUINode.styleSheet
    }
    
    public var anchoredPosition: CKUIAnchoredPosition {
        get {
            guard let values = getStyleValues(key: CKUICSSAttributes.anchoredPosition) else {
                return CKUIAnchoredPosition()
            }
            return CKUIAnchoredPosition(values: values)
        }
        
        set { setStyleValues(key: CKUICSSAttributes.anchoredPosition, values: newValue.toCSSValues()) }
    }
    
    public var sizeDelta: CKUISizeDelta {
        get {
            guard let values = getStyleValues(key: CKUICSSAttributes.sizeDelta) else {
                return CKUISizeDelta()
            }
            return CKUISizeDelta(values: values)
        }
        
        set { setStyleValues(key: CKUICSSAttributes.sizeDelta, values: newValue.toCSSValues()) }
    }
    
    public var anchors: CKUIAnchors {
        get {
            guard let values = getStyleValues(key: CKUICSSAttributes.anchors) else {
                return CKUIAnchors()
            }
            return CKUIAnchors(values: values)
        }
        
        set {
            let values = newValue.toCSSValues()
            let expanded = CKUICSSAttributeExpanders.expandAnchorsUnchecked(values: values)!
            for entry in expanded {
                setStyleValues(key: entry.key, values: entry.value)
            }
        }
    }
    
    public var pivot: CKUIPivot {
        get {
            guard let values = getStyleValues(key: CSSAttributes.transformOrigin) else {
                return CKUIPivot(x: 0.5, y: 0.5)
            }
            return CKUIPivot(values: values)
        }
        
        set { setStyleValues(key: CSSAttributes.transformOrigin, values: newValue.toCSSValues()) }
    }
    
    private let style: CKUIStyle
    
    public override var zRotation: CGFloat {
        get { 0 }
        set { }
    }
    
    public override var xScale: CGFloat {
        get { 1 }
        set { }
    }
    
    public override var yScale: CGFloat {
        get { 1 }
        set { }
    }
    
    public override func setScale(_ scale: CGFloat) { }
    
    public override var position: CGPoint {
        get { super.position }
        set { }
    }
    
    open override var frame: CGRect {
        guard let parent else { return CGRect() }
        
        let refFrame = referenceFrame.offsetBy(dx: -parent.position.x, dy: -parent.position.y)
        let anchoredFrame = anchors.computeAnchoredFrame(from: refFrame)
        let sd = sizeDelta
        let frameSize = CGSize(width: anchoredFrame.width + sd.horizontal, height: anchoredFrame.height + sd.vertical)
    
        let halfWidth = anchoredFrame.width * 0.5
        let halfHeight = anchoredFrame.height * 0.5
        
        let adjustedSizeDeltaHorizontal = sd.horizontal * pivot.x
        let adjustedSizeDeltaVertical = sd.vertical * pivot.y
        
        let anchoredPos = anchoredPosition
        
        let frameXmin = anchoredFrame.minX + anchoredPos.x - adjustedSizeDeltaHorizontal - halfWidth
        let frameYmin = anchoredFrame.minY + anchoredPos.y - adjustedSizeDeltaVertical - halfHeight
        
        return CGRect(x: frameXmin, y: frameYmin, width: frameSize.width, height: frameSize.height)
    }
    
    open var referenceFrame: CGRect { parent?.frame ?? CGRect() }
    
    public let type: String
    public let identifier: String?
    public private(set) var classes: [String]?
    
    public var ancestor: CSSConsumer? { parent as? CSSConsumer }
    
    public init(type: String, identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        self.type = type
        self.identifier = identifier
        self.classes = classes
        self.style = style ?? CKUIStyle()
        super.init()
    }
    
    public init(xmlElement: XMLElement) {
        self.type = xmlElement.attribute(forName: "type")!.stringValue!
        
        if let identifierAttribute = xmlElement.attribute(forName: "id") {
            identifier = identifierAttribute.stringValue!
        }
        else {
            identifier = nil
        }
        
        if let classAttribute = xmlElement.attribute(forName: "class") {
            let splitClasses = classAttribute.stringValue!.split(separator: " ")
            classes = splitClasses.map { String($0) }
        }
        else {
            classes = nil
        }
        
        let styleElement = xmlElement.firstElement(forName: "style")
        style = CKUIStyle(xmlElement: styleElement)
        
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func updateLayout() { }
    
    open func updatePosition() {
        guard let parent else {
            super.position = CGPoint()
            return
        }
        
        let frameInParent = frame
        let parentPosition = parent.position

        let x = frameInParent.minX - parentPosition.x + (frameInParent.size.width * pivot.x)
        let y = frameInParent.minY - parentPosition.y + (frameInParent.size.height * pivot.y)
        
        super.position = CGPoint(x: x, y: y)
    }
    
    final func update() {
        guard scene != nil else { return }
        
        updatePosition()

        for child in children {
            if let uiNode = child as? CKUIBaseNode {
                uiNode.update()
            }
        }
        
        updateLayout()
    }
    
    final func getStyleValues(key: String) -> [CSSValue]? { style[key] ?? styleSheet?.getValue(with: key, for: self) }
    final func getStyleValue(key: String, index: Int = 0) -> CSSValue? {
        guard
            let styleValues = getStyleValues(key: key),
            index < styleValues.count
        else {
            return nil
        }
        return styleValues[index]
    }
    
    final func getStyleColor(key: String) -> SKColor? {
        guard
            let value = getStyleValue(key: key),
            case let CSSValue.color(r, g, b, a) = value
        else {
            return nil
        }
        
        return SKColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
    
    final func setStyleValues(key: String, values: [CSSValue]) { style[key] = values }
    final func setStyleValue(key: String, value: CSSValue) { setStyleValues(key: key, values: [value]) }
    
}
