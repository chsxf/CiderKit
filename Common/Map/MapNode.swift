//
//  Map.swift
//  SKTestIsoMap
//
//  Created by Christophe SAUVEUR on 18/07/2021.
//

import SpriteKit
import GameplayKit

class MapNode: SKNode, Collection {
    
    static let elevationHeight: Int = 10
    
    static let halfWidth: Int = 24
    static let halfHeight: Int = 12
    
    private var regions: [MapRegion] = [MapRegion]()
    
    private let mapDescription: MapDescription
    
    var layerCount:Int { 3 } // Temporary code
    
    var startIndex: Int { regions.startIndex }
    var endIndex: Int { regions.endIndex }
    
    subscript(position: Int) -> MapRegion {
        return regions[position]
    }
    
    override required init() {
        fatalError("init() has not been implemented")
    }
    
    init(description mapDescription: MapDescription) {
        self.mapDescription = mapDescription
        
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
    
    func index(after i: Int) -> Int { regions.index(after: i) }
    
    private func sortRegions() {
        regions.sort()
        
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
        return Swift.max(diff, 0)
    }
    
    func getRightVisibleElevation(forX x: Int, andY y: Int, usingDefaultElevation defaultElevation: Int) -> Int {
        guard
            let cellElevation = getCellElevation(forX: x, andY: y),
            let rightCellElevation = getCellElevation(forX: x + 1, andY: y)
        else {
            return defaultElevation
        }
        
        let diff = cellElevation - rightCellElevation
        return Swift.max(diff, 0)
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
    
    func getMapCellEntity(atX x: Int, y: Int) -> GKEntity? {
        for region in regions {
            for cell in region.cellEntities {
                guard let cellComponent = cell.component(ofType: MapCellComponent.self) else {
                    continue
                }
                if cellComponent.mapX == x && cellComponent.mapY == y {
                    return cell
                }
            }
        }
        return nil
    }
    
}

#if CIDERKIT_EDITOR
extension MapNode {
    
    func increaseElevation(area: MapArea?) {
        var appliedOnRegion = false
        
        var needsRebuilding = false
        let previousRegionCount = regions.count
        
        var regionsToRemove = [MapRegion]()
        var newRegions = [MapRegion]()
        
        for region in regions {
            if area == nil || area!.contains(region.regionDescription.area) {
                appliedOnRegion = true
                if region.increaseElevation() {
                    needsRebuilding = true
                }
            }
            else if area != nil {
                guard let subdivisions = region.subdivide(subArea: area!) else {
                    continue
                }
                
                appliedOnRegion = true
                regionsToRemove.append(region)
                newRegions.append(contentsOf: subdivisions.otherSubdivisions)
                newRegions.append(subdivisions.mainSubdivision)
                let _ = subdivisions.mainSubdivision.increaseElevation()
                needsRebuilding = true
            }
        }
        
        if !appliedOnRegion {
            let newDescription = MapRegionDescription(area: area!, elevation: 1)
            let newRegion = MapRegion(forMap: self, description: newDescription, spriteRepository: mapDescription.spriteRepository)
            newRegions.append(newRegion)
            needsRebuilding = true
        }
        
        regions.removeAll(where: { regionsToRemove.contains($0) })
        regionsToRemove.forEach({ $0.removeFromParent() })
        regions.append(contentsOf: newRegions)
        newRegions.forEach({ addChild($0) })
        
        if previousRegionCount < regions.count {
            sortRegions()
        }
        
        if needsRebuilding {
            buildRegions()
        }
    }
    
    func decreaseElevation(area: MapArea?) {
        var needsRebuilding = false
        let previousRegionCount = regions.count
        
        var regionsToRemove = [MapRegion]()
        var newRegions = [MapRegion]()
        
        for region in regions {
            if area == nil || area!.contains(region.regionDescription.area) {
                if region.decreaseElevation() {
                    needsRebuilding = true
                }
            }
            else if area != nil {
                guard let subdivisions = region.subdivide(subArea: area!) else {
                    continue
                }
                
                regionsToRemove.append(region)
                newRegions.append(contentsOf: subdivisions.otherSubdivisions)
                newRegions.append(subdivisions.mainSubdivision)
                let _ = subdivisions.mainSubdivision.decreaseElevation()
                needsRebuilding = true
            }
        }
        
        regions.removeAll(where: { regionsToRemove.contains($0) })
        regionsToRemove.forEach({ $0.removeFromParent() })
        regions.append(contentsOf: newRegions)
        newRegions.forEach({ addChild($0) })
        
        if previousRegionCount < regions.count {
            sortRegions()
        }
        
        if needsRebuilding {
            buildRegions()
        }
    }
    
}
#endif
