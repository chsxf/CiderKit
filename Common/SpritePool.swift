import SpriteKit

final class SpritePool {
    
    private var availableSprites = [SKSpriteNode]()
    private var usedSprites = [SKSpriteNode]()
    
    func hasAvailableSprite() -> Bool {
        return !availableSprites.isEmpty
    }
    
    func getSprite() -> SKSpriteNode? {
        if hasAvailableSprite() {
            let sprite = availableSprites.popLast()!
            usedSprites.append(sprite)
            return sprite
        }
        return nil
    }
    
    func returnSprite(_ sprite: SKSpriteNode) {
        if usedSprites.contains(sprite) {
            usedSprites.removeAll { $0 == sprite }
            sprite.removeFromParent()
        }
        if !availableSprites.contains(sprite) {
            availableSprites.append(sprite)
        }
    }
    
    func returnAll() {
        usedSprites.forEach { $0.removeFromParent() }
        availableSprites.append(contentsOf: usedSprites)
        usedSprites.removeAll()
    }
    
}
