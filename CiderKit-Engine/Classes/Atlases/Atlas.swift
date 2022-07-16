import Foundation
import SpriteKit

public final class Atlas {
    
    public let editorOnly: Bool
    public let isVariant: Bool
    
    public let atlasTexture: SKTexture
    public private(set) var atlasSprites: [String: SKTexture]
    
    private var variants: [String: Atlas] = [:]
    
    init(from description: AtlasDescription, in bundle: Bundle, variant: String?) {
        editorOnly = description.editorOnly
        
        var textureName = description.texture
        if let variant = variant, let variants = description.variants {
            textureName = variants[variant]!
            isVariant = true
        }
        else {
            isVariant = false
        }

        #if os(macOS)
        let image = bundle.image(forResource: textureName)!
        #else
        let image = UIImage(named: textureName, in: bundle, with: nil)!
        #endif
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
    
    func add(variant: Atlas, for key: String) {
        variants[key] = variant
    }
    
    public func variant(for key: String) -> Atlas? {
        return variants[key]
    }
    
}
