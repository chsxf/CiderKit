import Foundation
@preconcurrency import SpriteKit

public enum AtlasErrors: Error {
    case unknownSprite
    case unknownVariant
}

public struct Atlas: StringKeysProvider, Sendable {

    public let name: String
    
    public let editorOnly: Bool
    public let isVariant: Bool
    
    public let atlasTexture: SKTexture
    public let atlasSprites: [String: SKTexture]
    
    private let variants: [String: Atlas]
    
    public var keys: any Collection<String> { atlasSprites.keys }
    
    private init(name: String, editorOnly: Bool, isVariant: Bool, atlasTexture: SKTexture, atlasSprites: [String: SKTexture], variants: [String: Atlas]) {
        self.name = name
        self.editorOnly = editorOnly
        self.isVariant = isVariant
        self.atlasTexture = atlasTexture
        self.atlasSprites = atlasSprites
        self.variants = variants
    }
    
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
        atlasSprites = Self.buildAtlasSprites(texture: atlasTexture, sprites: description.sprites)
        
        variants = [:]
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
        atlasSprites = Self.buildAtlasSprites(texture: atlasTexture, sprites: description.sprites)
        
        variants = [:]
    }
    
    private static func buildAtlasSprites(texture: SKTexture, sprites: [AtlasSpriteDescription]) -> [String: SKTexture] {
        var atlasSprites = [String: SKTexture]()
        for spriteDescription in sprites {
            let normalizedRect = spriteDescription.normalizedRect(in: texture)
            let sprite = SKTexture(rect: normalizedRect, in: texture)
            atlasSprites[spriteDescription.name] = sprite
        }
        return atlasSprites
    }
    
    public subscript(spriteName: String) -> SKTexture {
        get throws {
            guard let sprite = atlasSprites[spriteName] else {
                throw AtlasErrors.unknownSprite
            }
            return sprite
        }
    }
    
    public func variant(for key: String) throws -> Atlas {
        guard let variant = variants[key] else {
            throw AtlasErrors.unknownVariant
        }
        return variant
    }
    
    internal func with(newVariant: Atlas, for key: String) -> Atlas {
        var newVariants = variants
        newVariants[key] = newVariant
        return Atlas(name: name, editorOnly: editorOnly, isVariant: isVariant, atlasTexture: atlasTexture, atlasSprites: atlasSprites, variants: newVariants)
    }
    
}
