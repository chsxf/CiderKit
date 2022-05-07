import Foundation
import SpriteKit

enum AtlasesError: Error {
    case alreadyRegistered
}

final public class Atlases {
    
    public static let MAIN_ATLAS_KEY = "main"
    
    private static var loadedAtlases: [String: Atlas] = [:]
    
    static var main: Atlas { self[MAIN_ATLAS_KEY] }
    
    static public func load(atlases: [String: URL]) throws {
        for (key, url) in atlases {
            if loadedAtlases[key] != nil {
                throw AtlasesError.alreadyRegistered
            }
            
            let description: AtlasDescription = try Functions.load(url)
            let atlas = Atlas(from: description, variant: nil)
            loadedAtlases[key] = atlas
            
            if let variants = description.variants {
                for (variantKey, _) in variants {
                    let fullVariantKey = "\(key)~\(variantKey)"
                    
                    if loadedAtlases[fullVariantKey] != nil {
                        throw AtlasesError.alreadyRegistered
                    }
                    
                    let variantAtlas = Atlas(from: description, variant: variantKey)
                    loadedAtlases[fullVariantKey] = variantAtlas
                }
            }
        }
    }
    
    static subscript(name: String) -> Atlas {
        return loadedAtlases[name]!
    }
    
}
