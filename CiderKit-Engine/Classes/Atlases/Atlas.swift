import Foundation
import SpriteKit

public final class Atlas: StringKeysProvider {

    public let name: String
    
    public let editorOnly: Bool
    public let isVariant: Bool
    
    public let atlasTexture: SKTexture
    public private(set) var atlasSprites: [String: SKTexture]
    
    private var variants: [String: Atlas] = [:]
    
    public var keys: any Collection<String> { atlasSprites.keys }
    
    init(named name: String, from description: AtlasDescription, in bundle: Bundle, variant: String?) {
        self.name = name
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
    
    init(named name: String, from description: AtlasDescription, withTextureDirectoryURL directoryURL: URL, variant: String?) {
        self.name = name
        editorOnly = description.editorOnly
        
        var textureName = description.texture
        if let variant = variant, let variants = description.variants {
            textureName = variants[variant]!
            isVariant = true
        }
        else {
            isVariant = false
        }
        
        let url = URL(fileURLWithPath: "\(textureName).png", relativeTo: directoryURL)
        #if os(macOS)
        let image = NSImage(contentsOf: url)!
        #else
        let image = UIImage(contentsOfFile: url.path)!
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
