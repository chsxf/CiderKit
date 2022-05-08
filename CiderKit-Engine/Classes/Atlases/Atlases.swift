import Foundation
import SpriteKit

enum AtlasesError: Error {
    case alreadyRegistered
}

public struct AtlasLocator {
    public let url: URL
    public let bundle: Bundle
    
    public init(url: URL, bundle: Bundle) {
        self.url = url
        self.bundle = bundle
    }
}

final public class Atlases {
    
    public static let MAIN_ATLAS_KEY = "main"
    
    private static var loadedAtlases: [String: Atlas] = [:]
    
    static var main: Atlas { self[MAIN_ATLAS_KEY] }
    
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
                }
            }
        }
    }
    
    public static subscript(name: String) -> Atlas {
        return loadedAtlases[name]!
    }
    
}
