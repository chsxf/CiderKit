#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct PointerEventData {

    public let mouseButtonIndex: Int
    public let touchIndex: Int
    public let pointInView: CGPoint

    #if os(macOS)
    public init(with event: NSEvent, in view: NSView) {
        self.touchIndex = 0
        mouseButtonIndex = event.buttonNumber
        pointInView = view.convert(event.locationInWindow, from: nil)
    }
    #else
    public init(with event: UIEvent, in view: UIView) {
        
    }
    #endif

}
