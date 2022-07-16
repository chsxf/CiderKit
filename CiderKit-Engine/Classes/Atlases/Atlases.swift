import Foundation
import SpriteKit

enum AtlasesError: Error {
    case alreadyRegistered
}

final public class Atlases {
    
    public static let MAIN_ATLAS_KEY = "main"
    
    public private(set) static var loadedAtlases: [String: Atlas] = [:]
    
    static var main: Atlas? { self[MAIN_ATLAS_KEY] }
    
    public static func load(atlases: [String: AtlasLocator]) throws {
        for (key, locator) in atlases {
            if loadedAtlases[key] != nil {
                throw AtlasesError.alreadyRegistered
            }
            
            let description: AtlasDescription = try Functions.load(locator.url)
            let atlas = Atlas(from: description, in: locator.bundle, variant: nil)
            loadedAtlases[key] = atlas
            
            if let variants = description.variants {
                for (variantKey, _) in variants {
                    let fullVariantKey = "\(key)~\(variantKey)"
                    
                    if loadedAtlases[fullVariantKey] != nil {
                        throw AtlasesError.alreadyRegistered
                    }
                    
                    let variantAtlas = Atlas(from: description, in: locator.bundle, variant: variantKey)
                    loadedAtlases[fullVariantKey] = variantAtlas
                    
                    atlas.add(variant: variantAtlas, for: variantKey)
                }
            }
        }
    }
    
    public static subscript(name: String) -> Atlas? {
        return loadedAtlases[name]
    }
    
    public static subscript(locator: SpriteLocator) -> SKTexture? {
        guard let atlas = self[locator.atlasKey] else {
            return nil
        }
        
        var variant = atlas
        if let variantKey = locator.atlasVariantKey {
            guard let variantAtlas = atlas.variant(for: variantKey) else {
                return nil
            }
            variant = variantAtlas
        }
        
        return variant[locator.spriteName]
    }
    
}
