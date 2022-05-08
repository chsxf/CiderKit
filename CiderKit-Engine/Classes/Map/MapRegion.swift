import SpriteKit
import GameplayKit

public class MapRegion : SKNode, Identifiable, Comparable {
    
    private static var nextRegionId: Int = 1
    
    private let _id: Int;
    public var id: Int { _id }
    
    public var regionDescription: MapRegionDescription
    
    private weak var map: MapNode?
    
    public var cellEntities: [GKEntity] = []
    
    public init(forMap map: MapNode, description: MapRegionDescription) {
        _id = MapRegion.nextRegionId
        MapRegion.nextRegionId += 1
        
        self.regionDescription = description
        
        super.init()
        
        self.map = map
    }
    
    func build() {
        cellEntities.removeAll()
        removeAllChildren()
        
        let defaultRenderer = try! CellRenderers["default_cell"]
        
        let groundMaterial = try! defaultRenderer.groundMaterial
        let leftElevationMaterial = try! defaultRenderer.leftElevationMaterial
        let rightElevationMaterial = try! defaultRenderer.rightElevationMaterial
        
        if defaultRenderer.groundMaterialResetPolicy == .resetWithEachRegion {
            groundMaterial.reset()
        }
        if defaultRenderer.leftElevationMaterialResetPolicy == .resetWithEachRegion {
            leftElevationMaterial.reset()
        }
        if defaultRenderer.rightElevationMaterialResetPolicy == .resetWithEachRegion {
            rightElevationMaterial.reset()
        }
        
        for x in 0..<Int(regionDescription.area.width) {
            let mapX = x + Int(regionDescription.area.minX)
            
            for y in 0..<Int(regionDescription.area.height) {
                var localLeftElevationMaterialOverride: CustomSettings? = nil
                var localRightElevationMaterialOverride: CustomSettings? = nil
                
                let indexInRegion = y * regionDescription.area.width + x
                let mapY = y + Int(regionDescription.area.minY)
                
                let isoX = MapNode.halfWidth * (mapX - mapY)
                let isoY = (regionDescription.elevation * MapNode.elevationHeight) - MapNode.halfHeight * (mapY + mapX)
                
                let zForShader = Float(regionDescription.elevation) / 4.0
                
                if defaultRenderer.leftElevationMaterialResetPolicy == .resetWithEachCell {
                    leftElevationMaterial.reset()
                }
                let leftElevationCount = map!.getLeftVisibleElevation(forX: mapX, andY: mapY, usingDefaultElevation: regionDescription.elevation)
                for i in 0..<leftElevationCount {
                    if defaultRenderer.leftElevationMaterialResetPolicy == .resetAlways {
                        leftElevationMaterial.reset()
                    }
                    
                    let sprite = SKSpriteNode(texture: nil)
                    sprite.anchorPoint = CGPoint(x: 1, y: 1)
                    sprite.position = CGPoint(x: isoX, y: isoY - MapNode.halfHeight - (i * MapNode.elevationHeight))
                    sprite.zPosition = -2
                    
                    let z = zForShader - Float(i + 1) * 0.25
                    sprite.setValue(SKAttributeValue(vectorFloat3: vector_float3(Float(mapX), Float(mapY), z)), forAttribute: "a_position")
                    
                    localLeftElevationMaterialOverride = regionDescription.leftElevationMaterialOverride(at: indexInRegion)
                    leftElevationMaterial.applyOn(spriteNode: sprite, withLocalOverrides: localLeftElevationMaterialOverride)
                    
                    addChild(sprite)
                }

                if defaultRenderer.rightElevationMaterialResetPolicy == .resetWithEachCell {
                    rightElevationMaterial.reset()
                }
                let rightElevationCount = map!.getRightVisibleElevation(forX: mapX, andY: mapY, usingDefaultElevation: regionDescription.elevation)
                for i in 0..<rightElevationCount {
                    if defaultRenderer.rightElevationMaterialResetPolicy == .resetAlways {
                        rightElevationMaterial.reset()
                    }
                    
                    let sprite = SKSpriteNode(texture: nil)
                    sprite.anchorPoint = CGPoint(x: 0, y: 1)
                    sprite.position = CGPoint(x: isoX, y: isoY - MapNode.halfHeight - (i * MapNode.elevationHeight))
                    sprite.zPosition = -1
                    
                    let z = zForShader - Float(i + 1) * 0.25
                    sprite.setValue(SKAttributeValue(vectorFloat3: vector_float3(Float(mapX), Float(mapY), z)), forAttribute: "a_position")
                    
                    localRightElevationMaterialOverride = regionDescription.rightElevationMaterialOverride(at: indexInRegion)
                    rightElevationMaterial.applyOn(spriteNode: sprite, withLocalOverrides: localRightElevationMaterialOverride)
                    
                    addChild(sprite)
                }
            
                let groundMaterialResetPolicy = defaultRenderer.groundMaterialResetPolicy
                if groundMaterialResetPolicy == .resetAlways || groundMaterialResetPolicy == .resetWithEachCell {
                    groundMaterial.reset()
                }
                let sprite = SKSpriteNode(texture: nil)
                sprite.anchorPoint = CGPoint(x: 0.5, y: 1)
                sprite.position = CGPoint(x: isoX, y: isoY)
                
                let localGroundMaterialOverride = regionDescription.groundMaterialOverride(at: indexInRegion)
                groundMaterial.applyOn(spriteNode: sprite, withLocalOverrides: localGroundMaterialOverride)
                
                sprite.setValue(SKAttributeValue(vectorFloat3: vector_float3(Float(mapX), Float(mapY), zForShader)), forAttribute: "a_position")
                
                addChild(sprite)
                
                let entity = GKEntity()
                entity.addComponent(GKSKNodeComponent(node: sprite))
                let cell = MapCellComponent(region: self, mapX: mapX, mapY: mapY, elevation: regionDescription.elevation)
                cell.groundMaterialOverrides = localGroundMaterialOverride
                cell.leftElevationMaterialOverrides = localLeftElevationMaterialOverride
                cell.rightElevationMaterialOverrides = localRightElevationMaterialOverride
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
    
    public static func < (lhs: MapRegion, rhs: MapRegion) -> Bool {
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
    
    public func increaseElevation() -> Bool {
        regionDescription.elevation += 1
        return true
    }
    
    public func decreaseElevation() -> Bool {
        var needsRebuilding = false
        if regionDescription.elevation > 0 {
            regionDescription.elevation -= 1
            needsRebuilding = true
        }
        return needsRebuilding
    }
    
    public func subdivide(subArea: MapArea) -> (mainSubdivision: MapRegion, otherSubdivisions: [MapRegion])? {
        guard let intersection = regionDescription.area.intersection(subArea) else {
            return nil
        }
        
        let hasLeftSubdiv = intersection.minX > regionDescription.area.minX
        let hasRightSubdiv = intersection.maxX < regionDescription.area.maxX
        let hasBottomSubdiv = intersection.minY > regionDescription.area.minY
        let hasTopSubdiv = intersection.maxY < regionDescription.area.maxY
        
        let mainSubdivDescription = MapRegionDescription(byExporting: intersection, from: regionDescription)
        let mainSubdivision = MapRegion(forMap: map!, description: mainSubdivDescription)
        
        var otherSubdivisions = [MapRegion]()
        
        if hasLeftSubdiv {
            var area = regionDescription.area
            area.width = intersection.minX - area.minX
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: regionDescription)
            let otherMapRegion = MapRegion(forMap: map!, description: otherSubdivDescription)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasRightSubdiv {
            var area = regionDescription.area
            area.width = area.maxX - intersection.maxX
            area.x = intersection.maxX
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: regionDescription)
            let otherMapRegion = MapRegion(forMap: map!, description: otherSubdivDescription)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasTopSubdiv {
            let area = MapArea(x: intersection.minX, y: intersection.maxY, width: intersection.width, height: regionDescription.area.maxY - intersection.maxY)
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: regionDescription)
            let otherMapRegion = MapRegion(forMap: map!, description: otherSubdivDescription)
            otherSubdivisions.append(otherMapRegion)
        }
        
        if hasBottomSubdiv {
            let area = MapArea(x: intersection.minX, y: regionDescription.area.minY, width: intersection.width, height: intersection.minY - regionDescription.area.minY)
            let otherSubdivDescription = MapRegionDescription(byExporting: area, from: regionDescription)
            let otherMapRegion = MapRegion(forMap: map!, description: otherSubdivDescription)
            otherSubdivisions.append(otherMapRegion)
        }
        
        return (mainSubdivision, otherSubdivisions)
    }
    
}
