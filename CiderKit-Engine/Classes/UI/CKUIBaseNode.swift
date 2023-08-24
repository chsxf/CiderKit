import SpriteKit
import CiderCSSKit

open class CKUIBaseNode : SKNode, CSSConsumer {
    
    public var styleSheet: CKUIStyleSheet? {
        guard let parentUINode = parent as? CKUIBaseNode else { return nil }
        return parentUINode.styleSheet
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
        guard let parentUINode = parent as? CKUIBaseNode else { return CGRect() }
        
        let referenceFrame = parentUINode.frame
        let anchors = anchors
        let anchoredFrame = anchors.computeAnchoredFrame(from: referenceFrame)
        
        let sd = sizeDelta
        let anchoredPos = anchoredPosition
        let pivot = pivot
        let parentPivot = parentUINode.pivot
        
        let frameXmin = referenceFrame.width * (anchors.xmin - parentPivot.x) + anchoredPos.x - sd.horizontal * pivot.x
        let frameYmin = referenceFrame.height * (anchors.ymin - parentPivot.y) + anchoredPos.y - sd.vertical * pivot.y

        let frameSize = CGSize(width: anchoredFrame.width + sd.horizontal, height: anchoredFrame.height + sd.vertical)

        return CGRect(x: CGFloat(frameXmin), y: CGFloat(frameYmin), width: frameSize.width, height: frameSize.height)
    }
    
    open var referenceFrame: CGRect { parent?.frame ?? CGRect() }
    
    public let type: String
    public let identifier: String?
    public private(set) var classes: [String]?
    public private(set) var pseudoClasses: [String]? = []
    
    public var ancestor: CSSConsumer? { parent as? CSSConsumer }
    
    public init(type: String, identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil) {
        self.type = type
        self.identifier = identifier
        self.classes = classes
        self.style = style ?? CKUIStyle()
        super.init()
        zPosition = 1
        
        let shape = SKShapeNode(circleOfRadius: 1)
        shape.fillColor = SKColor.red
        shape.strokeColor = SKColor.orange
        addChild(shape)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func updateLayout() { }
    
    internal func updatePosition() {
        guard parent != nil else {
            super.position = CGPoint()
            return
        }
        
        let localFrame = frame
        let pivot = pivot
        
        let x = localFrame.minX + localFrame.width * pivot.x
        let y = localFrame.minY + localFrame.height * pivot.y

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
    
    final func getStyleColor(key: String, index: Int = 0) -> SKColor? {
        guard
            let value = getStyleValue(key: key, index: index),
            case let CSSValue.color(colorSpace, components) = value,
            colorSpace == .sRGB
        else {
            return nil
        }
        
        return SKColor(red: CGFloat(components[0]), green: CGFloat(components[1]), blue: CGFloat(components[2]), alpha: CGFloat(components[3]))
    }
    
    final func getStyleLength(key: String, unit: CSSLengthUnit = .px, index: Int = 0, allowZero: Bool = true) -> Float? {
        guard let value = getStyleValue(key: key, index: index) else { return nil }
        
        switch value {
        case let CSSValue.length(length, lengthUnit):
            return try! lengthUnit.convert(amount: length, to: unit)
        case let CSSValue.number(number):
            return allowZero && number == 0 ? 0 : nil
        default:
            return nil
        }
    }
    
    final func setStyleValues(key: String, values: [CSSValue]) { style[key] = values }
    final func setStyleValue(key: String, value: CSSValue) { setStyleValues(key: key, values: [value]) }
    
    public final func add(class: String) {
        if classes == nil {
            classes = [`class`]
            return
        }
        
        if !has(class: `class`) {
            classes!.append(`class`)
        }
    }
    
    public final func remove(class: String) {
        classes?.removeAll { $0 == `class` }
    }
    
    public final func toggle(class: String) {
        if has(class: `class`) {
            remove(class: `class`)
        }
        else {
            add(class: `class`)
        }
    }
    
    public final func has(class: String) -> Bool {
        classes?.contains(`class`) ?? false
    }
    
    public final func add(pseudoClass: String) {
        if pseudoClasses == nil {
            pseudoClasses = [pseudoClass]
            return
        }
        
        if !has(pseudoClass: pseudoClass) {
            pseudoClasses!.append(pseudoClass)
        }
    }
    
    public final func remove(pseudoClass: String) {
        pseudoClasses?.removeAll { $0 == pseudoClass }
    }
    
    public final func toggle(pseudoClass: String) {
        if has(pseudoClass: pseudoClass) {
            remove(pseudoClass: pseudoClass)
        }
        else {
            add(pseudoClass: pseudoClass)
        }
    }
    
    public final func has(pseudoClass: String) -> Bool {
        pseudoClasses?.contains(pseudoClass) ?? false
    }
    
}
