import Foundation
import SpriteKit

enum AtlasesError: Error {
    case alreadyPreloading
    case alreadyRegistered
}

final public class Atlases {
    
    private static let MAIN_ATLAS_KEY = "main"
    
    private static var loadedAtlases: [String: Atlas] = [:]
    
    static var main: Atlas { self[MAIN_ATLAS_KEY] }
    
    private static var preloading: Bool = false
    
    static public func preload(atlases: [String: String]) async throws {
        if preloading {
            throw AtlasesError.alreadyPreloading
        }
        
        preloading = true
        for (key, name) in atlases {
            if loadedAtlases[key] != nil {
                throw AtlasesError.alreadyRegistered
            }
            
            let atlas = Atlas(named: name)
            loadedAtlases[key] = atlas
            await atlas.preload()
        }
        preloading = false
    }
    
    static subscript(name: String) -> Atlas {
        return loadedAtlases[name]!
    }
    
}
