import SpriteKit

public extension SKNode {
    
    var isHiddenInHierarchy: Bool {
        var node: SKNode? = self
        repeat {
            if node!.isHidden {
                return true
            }
            node = node?.parent
        } while node != nil
        return false
    }
    
}
