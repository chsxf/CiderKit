import SpriteKit

final class EventBackdropNode: SKSpriteNode {

    let pointerDown = EventEmitter<PointerEventData, EventBackdropNode>()
    let pointerUp = EventEmitter<PointerEventData, EventBackdropNode>()
    let pointerMoved = EventEmitter<PointerEventData, EventBackdropNode>()

    init() {
        super.init(texture: CiderKitEngine.clearTexture, color: SKColor.clear, size: CGSize(width: 100, height: 100))
        isUserInteractionEnabled = true

        #if os(macOS)
        TrackingAreaManager.register(node: self)
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        if let view = scene?.view {
            pointerDown.notify(PointerEventData(with: event, in: view), from: self)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        if let view = scene?.view {
            pointerDown.notify(PointerEventData(with: event, in: view), from: self)
        }
    }

    override func otherMouseDown(with event: NSEvent) {
        if let view = scene?.view {
            pointerDown.notify(PointerEventData(with: event, in: view), from: self)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if let view = scene?.view {
            pointerUp.notify(PointerEventData(with: event, in: view), from: self)
        }
    }

    override func rightMouseUp(with event: NSEvent) {
        if let view = scene?.view {
            pointerUp.notify(PointerEventData(with: event, in: view), from: self)
        }
    }

    override func otherMouseUp(with event: NSEvent) {
        if let view = scene?.view {
            pointerUp.notify(PointerEventData(with: event, in: view), from: self)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        if let view = scene?.view, view.firstInteractiveNode(from: event) === self {
            pointerMoved.notify(PointerEventData(with: event, in: view), from: self)
        }
    }
    #endif

}
