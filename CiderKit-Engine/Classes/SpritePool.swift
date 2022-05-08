import SpriteKit

public final class SpritePool {
    
    private var availableSprites = [SKSpriteNode]()
    private var usedSprites = [SKSpriteNode]()
    
    public init() {
        
    }
    
    public func hasAvailableSprite() -> Bool {
        return !availableSprites.isEmpty
    }
    
    public func getSprite() -> SKSpriteNode? {
        if hasAvailableSprite() {
            let sprite = availableSprites.popLast()!
            usedSprites.append(sprite)
            return sprite
        }
        return nil
    }
    
    public func returnSprite(_ sprite: SKSpriteNode) {
        if usedSprites.contains(sprite) {
            usedSprites.removeAll { $0 == sprite }
            sprite.removeFromParent()
        }
        if !availableSprites.contains(sprite) {
            availableSprites.append(sprite)
        }
    }
    
    public func returnAll() {
        usedSprites.forEach { $0.removeFromParent() }
        availableSprites.append(contentsOf: usedSprites)
        usedSprites.removeAll()
    }
    
}
