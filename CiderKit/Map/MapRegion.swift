//
//  MapRegion.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 18/07/2021.
//

import SpriteKit

class MapRegion : SKNode {
    
    let regionDescription: MapRegionDescription
    let spriteRepository: SpriteRepository
    
    private weak var map: MapNode?
    
    init(forMap map: MapNode, description: MapRegionDescription, spriteRepository: SpriteRepository) {
        self.regionDescription = description
        self.spriteRepository = spriteRepository
        
        super.init()
        
        self.map = map
    }
    
    func build() {
        let defaultSprites = regionDescription.defaultSprites ?? spriteRepository.defaultSprites
        let texture = spriteRepository.getTile(withIndex: defaultSprites.tile)
        let leftElevationTexture = spriteRepository.getLeftElevation(withIndex: defaultSprites.leftElevation)
        let rightElevationTexture = spriteRepository.getRightElevation(withIndex: defaultSprites.rightElevation)
        
        for x in 0..<Int(regionDescription.rect.width) {
            let mapX = x + Int(regionDescription.rect.minX)
            
            for y in 0..<Int(regionDescription.rect.height) {
                let mapY = y + Int(regionDescription.rect.minY)
                
                let isoX = MapNode.halfWidth * (mapX - mapY)
                let isoY = (regionDescription.elevation * MapNode.elevationHeight) - MapNode.halfHeight * (mapY + mapX)
                
                let leftElevationCount = map!.getLeftVisibleElevation(forX: mapX, andY: mapY, usingDefaultElevation: regionDescription.elevation)
                for i in 0..<leftElevationCount {
                    let sprite = SKSpriteNode(texture: leftElevationTexture)
                    sprite.anchorPoint = CGPoint(x: 1, y: 1)
                    sprite.position = CGPoint(x: isoX, y: isoY - MapNode.halfHeight - (i * MapNode.elevationHeight))
                    sprite.zPosition = -2
                    addChild(sprite)
                }

                let rightElevationCount = map!.getRightVisibleElevation(forX: mapX, andY: mapY, usingDefaultElevation: regionDescription.elevation)
                for i in 0..<rightElevationCount {
                    let sprite = SKSpriteNode(texture: rightElevationTexture)
                    sprite.anchorPoint = CGPoint(x: 0, y: 1)
                    sprite.position = CGPoint(x: isoX, y: isoY - MapNode.halfHeight - (i * MapNode.elevationHeight))
                    sprite.zPosition = -1
                    addChild(sprite)
                }
                
                let sprite = SKSpriteNode(texture: texture)
                sprite.anchorPoint = CGPoint(x: 0.5, y: 1)
                sprite.position = CGPoint(x: isoX, y: isoY)
                addChild(sprite)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contains(x: Int, y: Int) -> Bool {
        return (x >= Int(regionDescription.rect.minX) && x < Int(regionDescription.rect.maxX)
                && y >= Int(regionDescription.rect.minY) && y < Int(regionDescription.rect.maxY))
    }
    
}
