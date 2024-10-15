import CoreGraphics
import CiderCSSKit

#if os(macOS)
import AppKit
#endif

public final class CKUICanvas: CKUIBaseNode {
    
    private let canvasStyleSheet: CKUIStyleSheet?
    public override var styleSheet: CKUIStyleSheet? { canvasStyleSheet ?? super.styleSheet }

    public override var frame: CGRect {
        let size = scene?.size ?? CGSize()
        return CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
    }
    
    public override var position: CGPoint {
        get { CGPoint() }
        set { }
    }
    
    public convenience init(identifier: String? = nil, styleSheet: CKUIStyleSheet? = nil) {
        var customData: [String: Any]? = nil
        if let styleSheet {
            customData = [ "stylesheet": styleSheet ]
        }
        
        self.init(identifier: identifier, style: CKUIStyle(attributes: "anchors: left bottom; transform-origin: center center;"), customData: customData)
    }
    
    required init(type: String = "canvas", identifier: String? = nil, classes: [String]? = nil, style: CKUIStyle? = nil, customData: [String:Any]? = nil) {
        canvasStyleSheet = customData?["stylesheet"] as? CKUIStyleSheet
        super.init(type: type, identifier: identifier, classes: classes, style: style, customData: customData)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func updatePosition() {
        updateVisibility()
        if isHidden {
            return
        }

        updateZPosition()
    }

    public override func updateLayout() { }

}
