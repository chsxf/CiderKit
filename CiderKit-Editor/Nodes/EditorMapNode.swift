import Foundation
import CiderKit_Engine
import GameplayKit

extension Notification.Name {
    static let mapDirtyStatusChanged = Notification.Name(rawValue: "mapDirtyStatusChanged")
}

class EditorMapNode: MapNode {

    var dirty: Bool = false {
        didSet {
            if dirty != oldValue {
                NotificationCenter.default.post(Notification(name: .mapDirtyStatusChanged))
            }
        }
    }
    
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
            let newDescription = MapRegionDescription(area: area!, elevation: 1, renderer: nil)
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
        
        regions.forEach { $0.removeFromParent() }
        regions.removeAll(where: { regionsToRemove.contains($0) })
        regions.append(contentsOf: newRegions)
        mergeRegions()
        regions.forEach { addChild($0) }
        
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
                    if let newRegionDescription = region.regionDescription.merged(with: region2.regionDescription) {
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
    
    override func buildRegions() {
        hoverableEntities = []
        super.buildRegions()
    }
    
    override func mapCellEntity(node: SKNode, for region: MapRegion, atX x: Int, y: Int, elevation: Int) -> GKEntity {
        let entity = super.mapCellEntity(node: node, for: region, atX: x, y: y, elevation: elevation)
        hoverableEntities.append(entity)
        return entity
    }
    
    override func mapCellComponent(for region: MapRegion, atX x: Int, y: Int, elevation: Int) -> MapCellComponent {
        return EditorMapCellComponent(region: region, mapX: x, mapY: y, elevation: elevation)
    }
    
    func add(light: PointLight) {
        lights.append(light)
        dirty = true
    }

    func remove(light: PointLight) {
        lights.removeAll(where: { $0 === light })
        dirty = true
    }
    
    @objc
    private func assetErased(notification: Notification) {
        if let assetComponent = notification.object as? AssetComponent {
            NotificationCenter.default.removeObserver(self, name: .selectableErased, object: assetComponent)
            
            let entity = assetComponent.entity!
            hoverableEntities.removeAll(where: { $0 === entity })
            
            let assetNode = assetComponent.entity!.component(ofType: GKSKNodeComponent.self)?.node
            
            for region in regions {
                if region.regionDescription.assets?.contains(where: { $0.id == assetComponent.placement.id }) ?? false {
                    region.regionDescription.assets!.removeAll(where: { $0.id == assetComponent.placement.id })
                    assetNode?.removeFromParent()
                    break
                }
            }
            
            dirty = true
        }
    }
    
    override func instantiateAsset(placement: AssetPlacement, at worldPosition: SIMD3<Float>) -> AssetInstance? {
        guard let instance = EditorAssetInstance(placement: placement, at: worldPosition) else { return nil }
        
        let entity = AssetComponent.entity(from: placement, with: instance)
        hoverableEntities.append(entity)
        let component = entity.component(ofType: AssetComponent.self)!
        NotificationCenter.default.addObserver(self, selector: #selector(assetErased(notification:)), name: .selectableErased, object: component)
        return instance
    }
    
}
