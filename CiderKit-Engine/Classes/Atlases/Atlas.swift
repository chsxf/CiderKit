import Foundation
import SpriteKit

public final class Atlas {
    
    public let atlasTexture: SKTexture
    private var atlasSprites: [String: SKTexture]
    
    init(from description: AtlasDescription, in bundle: Bundle, variant: String?) {
        var textureName = description.texture
        if let variant = variant, let variants = description.variants {
            textureName = variants[variant]!
        }
        
        let image = bundle.image(forResource: textureName)!
        atlasTexture = SKTexture(image: image)
        atlasTexture.filteringMode = .nearest
        atlasSprites = [:]
        for spriteDescription in description.sprites {
            let normalizedRect = spriteDescription.normalizedRect(in: atlasTexture)
            let sprite = SKTexture(rect: normalizedRect, in: atlasTexture)
            atlasSprites[spriteDescription.name] = sprite
        }
    }
    
    public subscript(spriteName: String) -> SKTexture? {
        return atlasSprites[spriteName]
    }
    
}
