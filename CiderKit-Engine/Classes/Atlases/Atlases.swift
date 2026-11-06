import Foundation
import SpriteKit
import os

enum AtlasesError: Error {
    case alreadyRegistered
    case unknownAtlas
}

public final class Atlases {
    
    public static let MAIN_ATLAS_KEY = "main"

    private static let internalLoadedAtlases: OSAllocatedUnfairLock<[String: Atlas]> = OSAllocatedUnfairLock(initialState: [:])
    public static var loadedAtlases: [String: Atlas] { internalLoadedAtlases.withLock { $0 } }

    static var main: Atlas? { try? self[MAIN_ATLAS_KEY] }

    public static func load(atlases: [String: AtlasLocator]) throws {
        let previousLoadedAtlases = loadedAtlases

        var newAtlases = [String: Atlas]()
        for (name, locator) in atlases {
            if previousLoadedAtlases[name] != nil {
                throw AtlasesError.alreadyRegistered
            }
            
            let description: AtlasDescription = try Functions.load(locator.url)
            var atlas = Atlas(named: name, from: description, in: locator.bundle, variant: nil)
            
            if let variants = description.variants {
                for (variantKey, _) in variants {
                    let fullVariantKey = "\(name)~\(variantKey)"
                    
                    if loadedAtlases[fullVariantKey] != nil {
                        throw AtlasesError.alreadyRegistered
                    }
                    
                    let variantAtlas = Atlas(named: name, from: description, in: locator.bundle, variant: variantKey)
                    newAtlases[fullVariantKey] = variantAtlas

                    atlas = atlas.with(newVariant: variantAtlas, for: variantKey)
                }
            }
            
            newAtlases[name] = atlas
        }

        let atlasesToMerge = newAtlases
        internalLoadedAtlases.withLock { state in
            for (name, atlas) in atlasesToMerge {
                state[name] = atlas
            }
        }
    }
    
    public static func load(atlases: [String: URL], withTexturesDirectoryURL directoryURL: URL) throws {
        let previousLoadedAtlases = loadedAtlases

        var newAtlases = [String: Atlas]()
        for (name, url) in atlases {
            if previousLoadedAtlases[name] != nil {
                throw AtlasesError.alreadyRegistered
            }
            
            let description: AtlasDescription = try Functions.load(url)
            var atlas = Atlas(named: name, from: description, withTextureDirectoryURL: directoryURL, variant: nil)
            
            if let variants = description.variants {
                for (variantKey, _) in variants {
                    let fullVariantKey = "\(name)~\(variantKey)"
                    
                    if previousLoadedAtlases[fullVariantKey] != nil {
                        throw AtlasesError.alreadyRegistered
                    }
                    
                    let variantAtlas = Atlas(named: name, from: description, withTextureDirectoryURL: directoryURL, variant: variantKey)
                    newAtlases[fullVariantKey] = variantAtlas

                    atlas = atlas.with(newVariant: variantAtlas, for: variantKey)
                }
            }
            
            newAtlases[name] = atlas
        }

        let atlasesToMerge = newAtlases
        internalLoadedAtlases.withLock { state in
            for (name, atlas) in atlasesToMerge {
                state[name] = atlas
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

    public static func preload(atlases: [String: String], relativeURL: URL, texturesRelativeURL: URL) throws {
        var atlasURLsByName = [String:URL]()
        for (name, fileName) in atlases {
            atlasURLsByName[name] = URL(fileURLWithPath: "\(fileName).ckatlas", relativeTo: relativeURL)
        }

        try Atlases.load(atlases: atlasURLsByName, withTexturesDirectoryURL: texturesRelativeURL)
    }

}
