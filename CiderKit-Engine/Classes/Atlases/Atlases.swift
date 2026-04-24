import Foundation
import SpriteKit

enum AtlasesError: Error {
    case alreadyRegistered
    case unknownAtlas
}

final public actor Atlases {
    
    public static let MAIN_ATLAS_KEY = "main"
    
    public private(set) static var loadedAtlases: [String: Atlas] = [:]
    
    static var main: Atlas? { try? self[MAIN_ATLAS_KEY] }

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
    
    public static subscript(name: String) -> Atlas {
        get throws {
            guard let atlas = loadedAtlases[name] else {
                throw AtlasesError.unknownAtlas
            }
            return atlas
        }
    }
    
    public static subscript(locator: SpriteLocator) -> SKTexture {
        get throws {
            let atlas = try self[locator.atlasKey]

            var variant = atlas
            if let variantKey = locator.atlasVariantKey {
                variant = try atlas.variant(for: variantKey)
            }

            return try variant[locator.spriteName]
        }
    }
    
}
