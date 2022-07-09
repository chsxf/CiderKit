import GameplayKit
import CiderKit_Engine

enum MoveToolContext: CaseIterable {
    
    case x
    case y
    case z
    
    var color: SKColor {
        switch self {
        case .x:
            return .red
        case .y:
            return .green
        case .z:
            return .blue
        }
    }
    
    var normalizedRect: CGRect {
        switch self {
        case .x:
            return CGRect(x: 0.667, y: 0.24, width: 0.302, height: 0.177)
        case .y:
            return CGRect(x: 0.031, y: 0.24, width: 0.302, height: 0.177)
        case .z:
            return CGRect(x: 0.448, y: 0.667, width: 0.104, height: 0.333)
        }
    }

}

class MoveToolComponent: GKComponent, Tool {

    private var hoveredContext: MoveToolContext? = nil
    
    weak var linkedSelectable: Selectable? = nil
    
    var enabled: Bool {
        get {
            if let node = entity?.component(ofType: GKSKNodeComponent.self)?.node {
                return !node.isHidden
            }
            return false
        }
        set {
            if let node = entity?.component(ofType: GKSKNodeComponent.self)?.node {
                node.isHidden = !newValue
            }
        }
    }
    
    var interactedWith: Bool { hoveredContext != nil }
    
    class func entity(parentNode: SKNode) -> GKEntity {
        let entity = GKEntity();
        entity.addComponent(MoveToolComponent())
        
        let node = MoveToolNode()
        parentNode.addChild(node)
        entity.addComponent(GKSKNodeComponent(node: node))
        
        return entity
    }
    
    func contains(sceneCoordinates: CGPoint) -> Bool {
        if let node = entity?.component(ofType: GKSKNodeComponent.self)?.node {
            let nodeFrame = node.calculateAccumulatedFrame()
            if nodeFrame.contains(sceneCoordinates) {
                for context in MoveToolContext.allCases {
                    let contextFrame = context.normalizedRect
                        .applying(CGAffineTransform(scaleX: nodeFrame.size.width, y: nodeFrame.size.height))
                        .applying(CGAffineTransform(translationX: nodeFrame.origin.x, y: nodeFrame.origin.y))
                    if contextFrame.contains(sceneCoordinates) {
                        hoveredContext = context
                        return true
                    }
                }
            }
        }
        hoveredContext = nil
        return false
    }
    
    func hovered() {
        if
            let hoveredContext = hoveredContext,
            let moveToolNode = entity?.component(ofType: GKSKNodeComponent.self)?.node as? MoveToolNode
        {
            moveToolNode.highlight(context: hoveredContext)
        }
    }
    
    func departed() {
        if let moveToolNode = entity?.component(ofType: GKSKNodeComponent.self)?.node as? MoveToolNode {
            moveToolNode.resetAllContexts()
        }
    }
    
    func dragInScene(byX x: CGFloat, y: CGFloat) {
        if let hoveredContext = hoveredContext {
            switch hoveredContext {
            case .x:
                let xOffset = x / CGFloat(MapNode.halfWidth)
                linkedSelectable?.dragBy(x: xOffset, y: 0, z: 0)

            case .y:
                let yOffset = -x / CGFloat(MapNode.halfWidth)
                linkedSelectable?.dragBy(x: 0, y: yOffset, z: 0)
            
            case .z:
                let zOffset = y / CGFloat(MapNode.elevationHeight)
                linkedSelectable?.dragBy(x: 0, y: 0, z: zOffset)
            }
        }
    }
    
}
