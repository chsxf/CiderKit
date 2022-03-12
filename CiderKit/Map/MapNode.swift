//
//  Map.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 18/07/2021.
//

import SpriteKit

class MapNode: SKNode {
    
    static let elevationHeight: Int = 10
    
    static let halfWidth: Int = 24
    static let halfHeight: Int = 12
    
    var regions: [MapRegion] = [MapRegion]()
    
    var layerCount:Int { 3 } // Temporary code
    
    init(description mapDescription: MapDescription) {
        super.init()
        
        for regionDescription in mapDescription.regions {
            let region = MapRegion(forMap: self, description: regionDescription, spriteRepository: mapDescription.spriteRepository)
            regions.append(region)
            addChild(region)
        }
        
        sortRegions()
        buildRegions()
        
        zPosition = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func sortRegions() {
        regions.sort { region1, region2 in
            let regionsOverlapOnX = (region1.regionDescription.rect.maxX > region2.regionDescription.rect.minX && region1.regionDescription.rect.minX < region2.regionDescription.rect.maxX)
            let regionsOverlapOnY = (region1.regionDescription.rect.maxY > region2.regionDescription.rect.minY && region1.regionDescription.rect.minY < region2.regionDescription.rect.maxY)
            
            if regionsOverlapOnX {
                return region1.regionDescription.rect.maxY < region2.regionDescription.rect.maxY
            }
            else if regionsOverlapOnY {
                return region1.regionDescription.rect.minX < region2.regionDescription.rect.minX
            }
            else {
                return region1.regionDescription.rect.maxY < region2.regionDescription.rect.maxY
            }
        }
        
        var index = 0
        for region in regions {
            region.zPosition = CGFloat(index)
            index += layerCount
        }
    }
    
    private func buildRegions() {
        for region in regions {
            region.build()
        }
    }
    
    func getLeftVisibleElevation(forX x: Int, andY y: Int, usingDefaultElevation defaultElevation: Int) -> Int {
        guard
            let cellElevation = getCellElevation(forX: x, andY: y),
            let leftCellElevation = getCellElevation(forX: x, andY: y + 1)
        else {
            return defaultElevation
        }
        
        let diff = cellElevation - leftCellElevation
        return max(diff, 0)
    }
    
    func getRightVisibleElevation(forX x: Int, andY y: Int, usingDefaultElevation defaultElevation: Int) -> Int {
        guard
            let cellElevation = getCellElevation(forX: x, andY: y),
            let rightCellElevation = getCellElevation(forX: x + 1, andY: y)
        else {
            return defaultElevation
        }
        
        let diff = cellElevation - rightCellElevation
        return max(diff, 0)
    }
    
    func getCellElevation(forX x: Int, andY y: Int) -> Int? {
        for region in regions {
            if region.containsMapCoordinates(x: x, y: y) {
                return region.regionDescription.elevation
            }
        }
        return nil
    }
    
    func getWorldPosition(atCellX x: Int, y: Int) -> CGPoint? {
        guard let elevation = getCellElevation(forX: x, andY: y) else {
            return nil
        }
        
        let isoX = MapNode.halfWidth * (x + y + 1)
        let isoY = MapNode.halfHeight * (y - x + 1) + (elevation * MapNode.elevationHeight)
        
        return CGPoint(x: isoX, y: isoY)
    }
    
}
