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
    
    public convenience init(styleSheet: CKUIStyleSheet? = nil) {
        self.init(style: CKUIStyle(attributes: "anchors: left bottom; transform-origin: center center;"), customData: ["stylesheet": styleSheet])
    }
    
    required init(type: String = "canvas", identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil, customData: [String:Any]? = nil) {
        canvasStyleSheet = customData!["stylesheet"] as? CKUIStyleSheet
        super.init(type: type, identifier: identifier, classes: classes, style: style, customData: customData)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func updatePosition() { }
    
    public override func updateLayout() { }
    
}
