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
        for (name, locator) in atlases {
            if loadedAtlases[name] != nil {
                throw AtlasesError.alreadyRegistered
            }
            
            let description: AtlasDescription = try Functions.load(locator.url)
            let atlas = Atlas(named: name, from: description, in: locator.bundle, variant: nil)
            loadedAtlases[name] = atlas
            
            if let variants = description.variants {
                for (variantKey, _) in variants {
                    let fullVariantKey = "\(name)~\(variantKey)"
                    
                    if loadedAtlases[fullVariantKey] != nil {
                        throw AtlasesError.alreadyRegistered
                    }
                    
                    let variantAtlas = Atlas(named: name, from: description, in: locator.bundle, variant: variantKey)
                    loadedAtlases[fullVariantKey] = variantAtlas
                    
                    atlas.add(variant: variantAtlas, for: variantKey)
                }
            }
        }
    }
    
    public static func load(atlases: [String: URL], withTexturesDirectoryURL directoryURL: URL) throws {
        for (name, url) in atlases {
            if loadedAtlases[name] != nil {
                throw AtlasesError.alreadyRegistered
            }
            
            let description: AtlasDescription = try Functions.load(url)
            let atlas = Atlas(named: name, from: description, withTextureDirectoryURL: directoryURL, variant: nil)
            loadedAtlases[name] = atlas
            
            if let variants = description.variants {
                for (variantKey, _) in variants {
                    let fullVariantKey = "\(name)~\(variantKey)"
                    
                    if loadedAtlases[fullVariantKey] != nil {
                        throw AtlasesError.alreadyRegistered
                    }
                    
                    let variantAtlas = Atlas(named: name, from: description, withTextureDirectoryURL: directoryURL, variant: variantKey)
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
