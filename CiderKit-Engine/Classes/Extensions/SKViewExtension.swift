import SpriteKit

#if os(macOS)
extension SKView {

    func firstInteractiveNode(from event: NSEvent) -> SKNode? {
        if let scene {
            let locationInView = self.convert(event.locationInWindow, from: nil)
            let locationInScene = scene.convertPoint(fromView: locationInView)
            let nodes = scene.nodes(at: locationInScene)
            if let firstNode = nodes.first, firstNode.isUserInteractionEnabled {
                return firstNode
            }
        }
        return nil
    }

}
#endif
