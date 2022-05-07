import Foundation
import SpriteKit

final class Atlas {
    
    private let atlasTexture: SKTexture
    private var atlasSprites: [String: SKTexture]
    
    init(from description: AtlasDescription, variant: String?) {
        var textureName = description.texture
        if let variant = variant, let variants = description.variants {
            textureName = variants[variant]!
        }
        atlasTexture = SKTexture(imageNamed: textureName)
        atlasTexture.filteringMode = .nearest
        atlasSprites = [:]
        for spriteDescription in description.sprites {
            let normalizedRect = spriteDescription.normalizedRect(in: atlasTexture)
            let sprite = SKTexture(rect: normalizedRect, in: atlasTexture)
            atlasSprites[spriteDescription.name] = sprite
        }
    }
    
    subscript(spriteName: String) -> SKTexture? {
        return atlasSprites[spriteName]
    }
    
}
