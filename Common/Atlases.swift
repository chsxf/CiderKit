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

final public class Atlases {
    
    private static let MAIN_ATLAS_KEY = "main"
    
    private static var loadedAtlases: [String: Atlas] = [:]
    
    static var main: Atlas { self[MAIN_ATLAS_KEY] }
    
    private static var preloading: Bool = false
    private static var remainingToPreload: Int = 0
    private static var preloadCallback: (() -> Void)? = nil
    
    static public func preload(atlases: [String: String], completionHandler: @escaping () -> Void) throws {
        if preloading {
            throw AtlasesError.alreadyPreloading
        }
        
        var atlasesToPreload = [Atlas]()
        
        preloading = true
        preloadCallback = completionHandler
        for (key, name) in atlases {
            if loadedAtlases[key] == nil {
                let atlas = Atlas(named: name)
                atlasesToPreload.append(atlas)
                loadedAtlases[key] = atlas
            }
        }
        
        remainingToPreload = atlasesToPreload.count
        for atlas in atlasesToPreload {
            atlas.preload(completionHandler: self.atlasPreloadedCallback)
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
