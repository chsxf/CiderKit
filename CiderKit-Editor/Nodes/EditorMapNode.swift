import Foundation
import CiderKit_Engine
import GameplayKit

class EditorMapNode: MapNode {

    @Published var dirty: Bool = false
    
    private(set) var hoverableEntities: [GKEntity] = []
    
    func increaseElevation(area: MapArea?) {
        var appliedOnRegion = false
        var needsRebuilding = false
        
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
            let newRegion = MapRegion(forMap: self, description: newDescription)
            newRegions.append(newRegion)
            needsRebuilding = true
        }
        
        regions.forEach({ $0.removeFromParent() })
        regions.removeAll(where: { regionsToRemove.contains($0) })
        regions.append(contentsOf: newRegions)
        mergeRegions()
        regions.forEach({ addChild($0) })
        
        if needsRebuilding {
            sortRegions()
            buildRegions()
            dirty = true
        }
    }
    
    func decreaseElevation(area: MapArea?) {
        var needsRebuilding = false
        
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
        
        regions.forEach({ $0.removeFromParent() })
        regions.removeAll(where: { regionsToRemove.contains($0) })
        regions.append(contentsOf: newRegions)
        mergeRegions()
        regions.forEach({ addChild($0) })
        
        if needsRebuilding {
            sortRegions()
            buildRegions()
            dirty = true
        }
    }
    
    private func mergeRegions() {
        guard regions.count > 1 else {
            return
        }
        
        var regionsHaveChanged: Bool
        repeat {
            regionsHaveChanged = false
            var i = 0
            while i < regions.count-1 {
                let region = regions[i]
                for i2 in i+1..<regions.count {
                    let region2 = regions[i2]
                    if let newRegionDescription = region.regionDescription.merging(with: region2.regionDescription) {
                        let newRegion = MapRegion(forMap: self, description: newRegionDescription)
                        regions[i] = newRegion
                        regions.remove(at: i2)
                        regionsHaveChanged = true
                        break
                    }
                }
                i += 1
            }
        } while regionsHaveChanged
    }
    
    override func mapCellEntity(node: SKNode, for region: MapRegion, atX x: Int, y: Int, elevation: Int) -> GKEntity {
        let entity = super.mapCellEntity(node: node, for: region, atX: x, y: y, elevation: elevation)
        hoverableEntities.append(entity)
        return entity
    }
    
    override func mapCellComponent(for region: MapRegion, atX x: Int, y: Int, elevation: Int) -> MapCellComponent {
        return EditorMapCellComponent(region: region, mapX: x, mapY: y, elevation: elevation)
    }
    
}
