import GameplayKit
import CiderKit_Engine

class ToolComponent<ContextType>: GKComponent, Tool where ContextType: ToolContext {
    
    private(set) var hoveredContext: ContextType? = nil
    
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
    
    required override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func entity(parentNode: SKNode) -> GKEntity {
        let entity = GKEntity();
        entity.addComponent(Self())
        
        let node = ToolNode(withContext: ContextType.self)
        parentNode.addChild(node)
        entity.addComponent(GKSKNodeComponent(node: node))
        
        return entity
    }
    
    func contains(sceneCoordinates: ScenePosition) -> Bool {
        if let node = entity?.component(ofType: GKSKNodeComponent.self)?.node {
            let nodeFrame = node.calculateAccumulatedFrame()
            if nodeFrame.contains(sceneCoordinates) {
                for context in ContextType.allCases {
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
            let moveToolNode = entity?.component(ofType: GKSKNodeComponent.self)?.node as? ToolNode<ContextType>
        {
            moveToolNode.highlight(context: hoveredContext)
        }
    }
    
    func departed() {
        if let moveToolNode = entity?.component(ofType: GKSKNodeComponent.self)?.node as? ToolNode<ContextType> {
            moveToolNode.resetAllContexts()
        }
    }
    
    func dragInScene(bySceneX x: CGFloat, y: CGFloat) { }
    
    func mouseUp(atSceneX x: CGFloat, y: CGFloat) { }
    
}
