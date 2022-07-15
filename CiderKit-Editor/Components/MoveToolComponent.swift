import GameplayKit
import CiderKit_Engine

enum MoveToolContext: ToolContext {
    
    case x
    case y
    case z
    
    var spriteImageFormat: String { "MoveTool-%@-arrow" }
    
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

class MoveToolComponent: ToolComponent<MoveToolContext> {

    required init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func dragInScene(byX x: CGFloat, y: CGFloat) {
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
