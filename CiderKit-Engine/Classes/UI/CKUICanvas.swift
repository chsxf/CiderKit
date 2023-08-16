import CoreGraphics
import CiderCSSKit

public final class CKUICanvas: CKUIBaseNode {
    
    private let canvasStyleSheet: CKUIStyleSheet?
    public override var styleSheet: CKUIStyleSheet? { canvasStyleSheet }
    
    public override var frame: CGRect {
        let size = scene?.size ?? CGSize()
        return CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
    }
    
    public override var position: CGPoint {
        get { CGPoint() }
        set { }
    }
    
    public init(styleSheet: CKUIStyleSheet? = nil) {
        self.canvasStyleSheet = styleSheet
        super.init(type: "canvas", style: CKUIStyle(attributes: "anchors: left bottom; transform-origin: center center;"))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func updatePosition() { }
    
    public override func updateLayout() { }
    
}
