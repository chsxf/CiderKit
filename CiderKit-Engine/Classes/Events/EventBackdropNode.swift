import SpriteKit
import Combine

final class EventBackdropNode: SKSpriteNode {

    typealias BackdropPointerEventData = (eventData: PointerEventData, sender: EventBackdropNode)

    let pointerDown = PassthroughSubject<BackdropPointerEventData, Never>()
    let pointerUp = PassthroughSubject<BackdropPointerEventData, Never>()
    let pointerMoved = PassthroughSubject<BackdropPointerEventData, Never>()

    init() {
        super.init(texture: CiderKitEngine.clearTexture, color: SKColor.clear, size: CGSize(width: 100, height: 100))
        isUserInteractionEnabled = true

        #if os(macOS)
        NotificationCenter.default.post(name: .trackingAreaRegistrationRequested, object: self)
        #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        if let view = scene?.view {
            pointerDown.send((PointerEventData(with: event, in: view), self))
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        if let view = scene?.view {
            pointerDown.send((PointerEventData(with: event, in: view), self))
        }
    }

    override func otherMouseDown(with event: NSEvent) {
        if let view = scene?.view {
            pointerDown.send((PointerEventData(with: event, in: view), self))
        }
    }

    override func mouseUp(with event: NSEvent) {
        if let view = scene?.view {
            pointerUp.send((PointerEventData(with: event, in: view), self))
        }
    }

    override func rightMouseUp(with event: NSEvent) {
        if let view = scene?.view {
            pointerUp.send((PointerEventData(with: event, in: view), self))
        }
    }

    override func otherMouseUp(with event: NSEvent) {
        if let view = scene?.view {
            pointerUp.send((PointerEventData(with: event, in: view), self))
        }
    }

    override func mouseMoved(with event: NSEvent) {
        if let view = scene?.view, view.firstInteractiveNode(from: event) === self {
            pointerMoved.send((PointerEventData(with: event, in: view), self))
        }
    }
    #endif

}
