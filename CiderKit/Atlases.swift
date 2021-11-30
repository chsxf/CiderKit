//
//  Atlases.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 15/11/2021.
//

import Foundation
import SpriteKit

enum AtlasesError: Error {
    case alreadyPreloading
}

final class Atlases {
    
    private static let MAIN_ATLAS_KEY = "main"
    
    private static var loadedAtlases: [String: Atlas] = [:]
    
    static var main: Atlas { self[MAIN_ATLAS_KEY] }
    
    private static var preloading: Bool = false
    private static var remainingToPreload: Int = 0
    private static var preloadCallback: (() -> Void)? = nil
    
    static func preload(atlases: [String: String], completionHandler: @escaping () -> Void) throws {
        if preloading {
            throw AtlasesError.alreadyPreloading
        }
        
        preloading = true
        preloadCallback = completionHandler
        remainingToPreload = 0
        for (key, name) in atlases {
            if loadedAtlases[key] == nil {
                remainingToPreload += 1
                
                let atlas = Atlas(named: name)
                loadedAtlases[key] = atlas
                atlas.preload(completionHandler: self.atlasPreloadedCallback)
            }
        }
    }
    
    private static func atlasPreloadedCallback() -> Void {
        remainingToPreload -= 1
        
        if remainingToPreload == 0 {
            preloading = false
            preloadCallback!()
            preloadCallback = nil
        }
    }
    
    static subscript(name: String) -> Atlas {
        return loadedAtlases[name]!
    }
    
}
