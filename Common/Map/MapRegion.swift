//
//  MapRegion.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 18/07/2021.
//

import SpriteKit
import GameplayKit

class MapRegion : SKNode, Identifiable, Comparable {
    
    private static var nextRegionId: Int = 1
    
    private let _id: Int;
    var id: Int { _id }
    
    var regionDescription: MapRegionDescription
    
    private weak var map: MapNode?
    
    var cellEntities: [GKEntity] = []
    
    init(forMap map: MapNode, description: MapRegionDescription) {
        _id = MapRegion.nextRegionId
        MapRegion.nextRegionId += 1
        
        self.regionDescription = description
        
        super.init()
        
        self.map = map
    }
    
    func build() {
        cellEntities.removeAll()
        removeAllChildren()
        
        let texture = Atlases.main["default_tile"]
        let leftElevationTexture = Atlases.main["default_elevation_left"]
        let rightElevationTexture = Atlases.main["default_elevation_right"]
        
        for x in 0..<Int(regionDescription.area.width) {
            let mapX = x + Int(regionDescription.area.minX)
            
            for y in 0..<Int(regionDescription.area.height) {
                let mapY = y + Int(regionDescription.area.minY)
                
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
                
                let entity = GKEntity()
                entity.addComponent(GKSKNodeComponent(node: sprite))
                let cell = MapCellComponent(region: self, mapX: mapX, mapY: mapY, elevation: regionDescription.elevation)
                entity.addComponent(cell)
                cellEntities.append(entity)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func containsMapCoordinates(x: Int, y: Int) -> Bool {
        return (x >= Int(regionDescription.area.minX) && x < Int(regionDescription.area.maxX)
                && y >= Int(regionDescription.area.minY) && y < Int(regionDescription.area.maxY))
    }
    
    static func < (lhs: MapRegion, rhs: MapRegion) -> Bool {
        let regionsOverlapOnX = (lhs.regionDescription.area.maxX > rhs.regionDescription.area.minX && lhs.regionDescription.area.minX < rhs.regionDescription.area.maxX)
        let regionsOverlapOnY = (lhs.regionDescription.area.maxY > rhs.regionDescription.area.minY && lhs.regionDescription.area.minY < rhs.regionDescription.area.maxY)
        
        var result: Bool
        if regionsOverlapOnX {
            result = lhs.regionDescription.area.minY < rhs.regionDescription.area.minY
        }
        else if regionsOverlapOnY {
            result = lhs.regionDescription.area.minX < rhs.regionDescription.area.minX
        }
        else {
            result = lhs.regionDescription.area.minY < rhs.regionDescription.area.minY
        }
        return result
    }
    
}

#if CIDERKIT_EDITOR
extension MapRegion {
    
    func increaseElevation() -> Bool {
        regionDescription.elevation += 1
        return true
    }
    
    func decreaseElevation() -> Bool {
        var needsRebuilding = false
        if regionDescription.elevation > 0 {
            regionDescription.elevation -= 1
            needsRebuilding = true
        }
        return needsRebuilding
    }
    
    func subdivide(subArea: MapArea) -> (mainSubdivision: MapRegion, otherSubdivisions: [MapRegion])? {
        guard let intersection = regionDescription.area.intersection(subArea) else {
            return nil
        }
        
        let hasLeftSubdiv = intersection.minX > regionDescription.area.minX
        let hasRightSubdiv = intersection.maxX < regionDescription.area.maxX
        let hasBottomSubdiv = intersection.minY > regionDescription.area.minY
        let hasTopSubdiv = intersection.maxY < regionDescription.area.maxY
        
        let mainSubdivDescription = MapRegionDescription(area: intersection, elevation: regionDescription.elevation)
        let mainSubdivision = MapRegion(forMap: map!, description: mainSubdivDescription)
        
        var otherSubdivisions = [MapRegion]()
        
        if hasLeftSubdiv {
            var area = regionDescription.area
            area.width = intersection.minX - area.minX
            let otherSubdivDescription = MapRegionDescription(area: area, elevation: regionDescription.elevation)
            let otherMapRegion = MapRegion(forMap: map!, description: otherSubdivDescription)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasRightSubdiv {
            var area = regionDescription.area
            area.width = area.maxX - intersection.maxX
            area.x = intersection.maxX
            let otherSubdivDescription = MapRegionDescription(area: area, elevation: regionDescription.elevation)
            let otherMapRegion = MapRegion(forMap: map!, description: otherSubdivDescription)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasTopSubdiv {
            let area = MapArea(x: intersection.minX, y: intersection.maxY, width: intersection.width, height: regionDescription.area.maxY - intersection.maxY)
            let otherSubdivDescription = MapRegionDescription(area: area, elevation: regionDescription.elevation)
            let otherMapRegion = MapRegion(forMap: map!, description: otherSubdivDescription)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasBottomSubdiv {
            let area = MapArea(x: intersection.minX, y: regionDescription.area.minY, width: intersection.width, height: intersection.minY - regionDescription.area.minY)
            let otherSubdivDescription = MapRegionDescription(area: area, elevation: regionDescription.elevation)
            let otherMapRegion = MapRegion(forMap: map!, description: otherSubdivDescription)
            otherSubdivisions.append(otherMapRegion)
        }
        
        return (mainSubdivision, otherSubdivisions)
    }
    
}
#endif
