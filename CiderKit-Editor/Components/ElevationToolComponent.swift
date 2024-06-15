import SpriteKit
import CiderKit_Engine

extension Notification.Name {
    static let elevationChangeRequested = Notification.Name(rawValue: "elevationChangeRequested")
}

enum ElevationToolContext: ToolContext {
    
    case up
    case down
    
    var spriteImageFormat: String { "ElevationTool-%@" }
    
    var color: SKColor {
        switch self {
        case .up:
            return .green
        case .down:
            return .red
        }
    }
    
    var normalizedRect: CGRect {
        switch self {
        case .up:
            return CGRect(x: 0.25, y: 0.5, width: 0.5, height: 0.5)
        case .down:
            return CGRect(x: 0.25, y: 0, width: 0.5, height: 0.5)
        }
    }
    
}

class ElevationToolComponent: ToolComponent<ElevationToolContext> {
    
    required init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseUp(atSceneX x: CGFloat, y: CGFloat) {
        if let hoveredContext = hoveredContext {
            NotificationCenter.default.post(Notification(name: .elevationChangeRequested, object: hoveredContext))
        }
    }
    
}
