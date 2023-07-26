import CiderCSSKit

public final class CKUICanvas: CKUIBaseNode {
    
    private let canvasStyleSheet: CKUIStyleSheet?
    public override var styleSheet: CKUIStyleSheet? { canvasStyleSheet }
    
    public override var referenceFrame: CGRect { CGRect(origin: CGPoint(), size: scene?.size ?? CGSize()) }
    
    public init(style: CKUIStyle? = nil, styleSheet: CKUIStyleSheet? = nil) {
        self.canvasStyleSheet = styleSheet
        super.init(type: "canvas", style: style ?? CKUIStyle(attributes: "anchors: left right bottom top; transform-origin: center center;"))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
