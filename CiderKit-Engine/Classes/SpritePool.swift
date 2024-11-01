import SpriteKit

@MainActor
public final class SpritePool: Pool<SKSpriteNode> {
    
    public init() {
        super.init(deallocation: { $0.removeFromParent() })
    }
    
}
