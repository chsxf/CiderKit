#if os(macOS)
import SpriteKit

public final class TrackingAreaManager {
    
    fileprivate struct TrackingAreaData {
        public var trackingArea: NSTrackingArea
        public var nodePosition: CGPoint
        public var nodeFrame: CGRect
    }
    
    static weak var scene: SKScene?
    
    private static var previousViewSize: CGSize?
    
    private static var nodes = [SKNode]()
    private static var trackingAreas: [SKNode:TrackingAreaData] = [:]
    
    public static func register(node: SKNode) -> Void {
        if !nodes.contains(node) {
            nodes.append(node)
        }
    }
    
    public static func unregister(node: SKNode) -> Void {
        if nodes.contains(node) {
            if let trackingAreaData = trackingAreas[node] {
                scene?.view?.removeTrackingArea(trackingAreaData.trackingArea)
            }
            trackingAreas[node] = nil
            nodes.removeAll { $0 == node }
        }
    }
    
    static func update() -> Void {
        guard let view = scene?.view else { return }
        
        for i in stride(from: nodes.count - 1, through: 0, by: -1) {
            let node = nodes[i]
            if node.scene == nil {
                unregister(node: node)
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
                    trackingAreas[node] = TrackingAreaData(trackingArea: addTrackingArea(to: view, from: node, with: nodeFrame), nodePosition: nodePosition, nodeFrame: nodeFrame)
                }
            }
            else if let trackingArea = trackingAreaData?.trackingArea {
                view.removeTrackingArea(trackingArea)
                trackingAreas[node] = nil
            }
        }
    }
    
    fileprivate static func addTrackingArea(to view: SKView, from node: SKNode, with nodeFrame: CGRect) -> NSTrackingArea {
        let bottomLeftInScene = scene!.convert(CGPoint(x: nodeFrame.minX, y: nodeFrame.minY), from: node.parent!)
        let topRightInScene = scene!.convert(CGPoint(x: nodeFrame.maxX, y: nodeFrame.maxY), from: node.parent!)
        
        let bottomLeftInView = view.convert(bottomLeftInScene, from: scene!)
        let topRightInView = view.convert(topRightInScene, from: scene!)
        
        let width = abs(topRightInView.x - bottomLeftInView.x)
        let height = abs(topRightInView.y - bottomLeftInView.y)
        let viewRect = NSRect(x: bottomLeftInView.x, y: bottomLeftInView.y, width: width, height: height)
        let trackingArea = NSTrackingArea(rect: viewRect, options: [ .mouseEnteredAndExited, .activeInKeyWindow ], owner: node)
        view.addTrackingArea(trackingArea)
        return trackingArea
    }
    
}
#endif
