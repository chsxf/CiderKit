//
//  MapDescription.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 12/10/2021.
//

import Foundation
import SpriteKit

struct MapDescription: Codable {
    var spriteRepository: SpriteRepository
    var regions: [MapRegionDescription]
}

struct SpriteLocation: Codable {
    var atlasName: String?
    var spriteName: String
}

struct SpriteRepository: Codable {
    var tiles: [SpriteLocation]
    var leftElevations: [SpriteLocation]
    var rightElevations: [SpriteLocation]
    
    var defaultSprites: DefaultSprites
    
    var defaultTile: SKTexture { getTile(withIndex: defaultSprites.tile) }
    var defaultLeftElevation: SKTexture { getLeftElevation(withIndex: defaultSprites.leftElevation) }
    var defaultRightElevation: SKTexture { getRightElevation(withIndex: defaultSprites.rightElevation) }
    
    func getTile(withIndex index: Int) -> SKTexture {
        let location = tiles[index]
        let atlas = (location.atlasName != nil) ? Atlases[location.atlasName!] : Atlases.main
        return atlas[location.spriteName]
    }
    
    func getLeftElevation(withIndex index: Int) -> SKTexture {
        let location = leftElevations[index]
        let atlas = (location.atlasName != nil) ? Atlases[location.atlasName!] : Atlases.main
        return atlas[location.spriteName]
    }
    
    func getRightElevation(withIndex index: Int) -> SKTexture {
        let location = rightElevations[index]
        let atlas = (location.atlasName != nil) ? Atlases[location.atlasName!] : Atlases.main
        return atlas[location.spriteName]
    }
}

struct DefaultSprites: Codable {
    var tile: Int
    var leftElevation: Int
    var rightElevation: Int
}

struct MapRegionDescription: Codable {
    private var x: Int
    private var y: Int
    
    private var width: Int
    private var height: Int
    
    var elevation: Int
    
    var defaultSprites: DefaultSprites?
    
    var area: MapArea { MapArea(x: x, y: y, width: width, height: height) }
    
    init(x: Int, y: Int, width: Int, height: Int, elevation: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.elevation = elevation
    }
    
    init(area: MapArea, elevation: Int) {
        self.init(x: area.minX, y: area.minY, width: area.width, height: area.height, elevation: elevation)
    }
    
}
