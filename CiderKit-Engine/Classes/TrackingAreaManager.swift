#if os(macOS)
import SpriteKit

public extension Notification.Name {

    static let trackingAreaRegistrationRequested = Self.init(rawValue: "trackingAreaRegistrationRequested")
    static let trackingAreaUnregistrationRequested = Self.init(rawValue: "trackingAreaUnregistrationRequested")

}

public final class TrackingAreaManager {
    
    fileprivate struct TrackingAreaData {
        public var trackingArea: NSTrackingArea
        public var nodePosition: ScenePosition
        public var nodeFrame: CGRect
    }

    private let scene: SKScene

    private var previousViewSize: CGSize?
    private var nodes = [SKNode]()
    private var trackingAreas = [SKNode: TrackingAreaData]()

    public init(scene: SKScene) {
        self.scene = scene;

        NotificationCenter.default.addObserver(self, selector: #selector(onTrackingAreaRegistrationRequested(_:)), name: .trackingAreaRegistrationRequested, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTrackingAreaUnregistrationRequested(_:)), name: .trackingAreaUnregistrationRequested, object: nil)
    }

    @objc
    private func onTrackingAreaRegistrationRequested(_ notification: Notification) -> Void {
        guard let node = notification.object as? SKNode else { return }
        register(node: node)
    }

    private func register(node: SKNode) {
        if !nodes.contains(node) {
            nodes.append(node)
        }
    }

    @objc
    private func onTrackingAreaUnregistrationRequested(_ notification: Notification) -> Void {
        guard let node = notification.object as? SKNode else { return }
        unregister(node: node)
    }

    private func unregister(node: SKNode) {
        if nodes.contains(node) {
            nodes.removeAll { $0 === node }
        }
    }

    @MainActor
    private func removeTrackingArea(node: SKNode) {
        if let trackingAreaData = trackingAreas[node] {
            trackingAreas[node] = nil
            scene.view?.removeTrackingArea(trackingAreaData.trackingArea)
        }
    }

    @MainActor
    func update() -> Void {
        guard let view = scene.view else { return }
        
        for i in stride(from: nodes.count - 1, through: 0, by: -1) {
            let node = nodes[i]
            if node.scene == nil {
                unregister(node: node)
                removeTrackingArea(node: node)
            }
        }

        let trackingAreaDataNodes = trackingAreas.keys
        for trackingAreaDataNode in trackingAreaDataNodes {
            if !nodes.contains(trackingAreaDataNode) {
                removeTrackingArea(node: trackingAreaDataNode)
            }
        }

        var invalidateTrackingAreas = false
        let viewSize = view.frame.size
        if previousViewSize != nil && viewSize != previousViewSize! {
            invalidateTrackingAreas = true
        }
        previousViewSize = viewSize
        
        if invalidateTrackingAreas {
            for (_, trackingAreaData) in trackingAreas {
                view.removeTrackingArea(trackingAreaData.trackingArea)
            }
            trackingAreas.removeAll(keepingCapacity: true)
        }
        
        for node in nodes {
            let trackingAreaData = trackingAreas[node]
            
            let nodeIsVisible = !node.isHiddenInHierarchy
            if nodeIsVisible {
                let nodeFrame = node.frame
                let nodePosition = node.position
                if trackingAreaData?.nodeFrame != nodeFrame || trackingAreaData?.nodePosition != node.position {
                    if let trackingArea = trackingAreaData?.trackingArea {
                        view.removeTrackingArea(trackingArea)
                    }
                    trackingAreas[node] = TrackingAreaData(trackingArea: Self.addTrackingArea(to: view, in: scene, from: node, with: nodeFrame), nodePosition: nodePosition, nodeFrame: nodeFrame)
                }
            }
            else if let trackingArea = trackingAreaData?.trackingArea {
                view.removeTrackingArea(trackingArea)
                trackingAreas[node] = nil
            }
        }
    }

    @MainActor
    fileprivate static func addTrackingArea(to view: SKView, in scene: SKScene, from node: SKNode, with nodeFrame: CGRect) -> NSTrackingArea {
        let bottomLeftInScene = scene.convert(CGPoint(x: nodeFrame.minX, y: nodeFrame.minY), from: node.parent!)
        let topRightInScene = scene.convert(CGPoint(x: nodeFrame.maxX, y: nodeFrame.maxY), from: node.parent!)
        
        let bottomLeftInView = view.convert(bottomLeftInScene, from: scene)
        let topRightInView = view.convert(topRightInScene, from: scene)

        let width = abs(topRightInView.x - bottomLeftInView.x)
        let height = abs(topRightInView.y - bottomLeftInView.y)
        let viewRect = NSRect(x: bottomLeftInView.x, y: bottomLeftInView.y, width: width, height: height)
        let trackingArea = NSTrackingArea(rect: viewRect, options: [ .mouseEnteredAndExited, .activeInKeyWindow, .mouseMoved ], owner: node)
        view.addTrackingArea(trackingArea)
        return trackingArea
    }
    
}
#endif
