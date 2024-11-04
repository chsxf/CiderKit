import SpriteKit
import GameplayKit

public enum MapRegionErrors : Error {
    case assetTooCloseToRegionBorder
    case otherAssetInTheWay
}

public class MapRegion : SKNode, Identifiable, @preconcurrency Comparable {
    
    private static var nextRegionId: Int = 1
    
    public let id: Int

    public var regionDescription: MapRegionDescription
    
    private weak var map: MapNode?
    
    public private(set) var cellEntities: [GKEntity] = []
    public private(set) var assetInstances: [AssetInstance] = []
    
    var layerCount: Int { 10 }
    public var elevation: Int { regionDescription.elevation }
    
    public init(forMap map: MapNode, description: MapRegionDescription) {
        id = MapRegion.nextRegionId
        MapRegion.nextRegionId += 1
        
        self.regionDescription = description
        
        super.init()
        
        self.map = map
    }
    
    func build() {
        cellEntities.removeAll()
        assetInstances.forEach { map?.remove(assetInstance: $0) }
        assetInstances.removeAll()
        removeAllChildren()
        
        let rendererName = regionDescription.renderer ?? "default_cell"
        let renderer = try! CellRenderers[rendererName]
        
        let groundMaterial = try! renderer.groundMaterial
        let leftElevationMaterial = try! renderer.leftElevationMaterial
        let rightElevationMaterial = try! renderer.rightElevationMaterial
        
        if renderer.groundMaterialResetPolicy == .resetWithEachRegion {
            groundMaterial.reset()
        }
        if renderer.leftElevationMaterialResetPolicy == .resetWithEachRegion {
            leftElevationMaterial.reset()
        }
        if renderer.rightElevationMaterialResetPolicy == .resetWithEachRegion {
            rightElevationMaterial.reset()
        }
        
        for x in 0..<Int(regionDescription.area.width) {
            let mapX = x + Int(regionDescription.area.minX)
            
            for y in 0..<Int(regionDescription.area.height) {
                var localLeftElevationMaterialOverride: CustomSettings? = nil
                var localRightElevationMaterialOverride: CustomSettings? = nil
                
                let indexInRegion = y * regionDescription.area.width + x
                let mapY = y + Int(regionDescription.area.minY)
                
                let baseScenePosition = MapNode.worldToScene(WorldPosition(Float(mapX), Float(mapY), Float(regionDescription.elevation)))

                let zForShader = Float(regionDescription.elevation)
                
                if renderer.leftElevationMaterialResetPolicy == .resetWithEachCell {
                    leftElevationMaterial.reset()
                }
                let leftElevationCount = map!.getLeftVisibleElevation(forX: mapX, y: mapY, usingDefaultElevation: regionDescription.elevation)
                for i in 0..<leftElevationCount {
                    if renderer.leftElevationMaterialResetPolicy == .resetAlways {
                        leftElevationMaterial.reset()
                    }
                    
                    let sprite = SKSpriteNode(texture: nil)
                    sprite.anchorPoint = CGPoint(x: 1, y: 1)
                    sprite.position = baseScenePosition + ScenePosition(x: 0, y: -MapNode.halfHeight - (i * MapNode.elevationHeight))
                    sprite.zPosition = -2
                    
                    let z = zForShader - Float(i + 1)
                    sprite.attributeValues = [
                        CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: WorldPosition(Float(mapX), Float(mapY), z)),
                        CiderKitEngine.ShaderAttributeName.sizeAndFlip.rawValue: SKAttributeValue(vectorFloat4: SIMD4(WorldPosition(1, 1, 1), 0))
                    ]
                    
                    localLeftElevationMaterialOverride = regionDescription.leftElevationMaterialOverride(at: indexInRegion)
                    leftElevationMaterial.applyOn(spriteNode: sprite, withLocalOverrides: localLeftElevationMaterialOverride)
                    
                    addChild(sprite)
                }

                if renderer.rightElevationMaterialResetPolicy == .resetWithEachCell {
                    rightElevationMaterial.reset()
                }
                let rightElevationCount = map!.getRightVisibleElevation(forX: mapX, y: mapY, usingDefaultElevation: regionDescription.elevation)
                for i in 0..<rightElevationCount {
                    if renderer.rightElevationMaterialResetPolicy == .resetAlways {
                        rightElevationMaterial.reset()
                    }
                    
                    let sprite = SKSpriteNode(texture: nil)
                    sprite.anchorPoint = CGPoint(x: 0, y: 1)
                    sprite.position = baseScenePosition + ScenePosition(x: 0, y: -MapNode.halfHeight - (i * MapNode.elevationHeight))
                    sprite.zPosition = -1
                    
                    let z = zForShader - Float(i + 1)
                    sprite.attributeValues = [
                        CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: WorldPosition(Float(mapX), Float(mapY), z)),
                        CiderKitEngine.ShaderAttributeName.sizeAndFlip.rawValue: SKAttributeValue(vectorFloat4: SIMD4(WorldPosition(1, 1, 1), 0))
                    ]
                    
                    localRightElevationMaterialOverride = regionDescription.rightElevationMaterialOverride(at: indexInRegion)
                    rightElevationMaterial.applyOn(spriteNode: sprite, withLocalOverrides: localRightElevationMaterialOverride)
                    
                    addChild(sprite)
                }
            
                let groundMaterialResetPolicy = renderer.groundMaterialResetPolicy
                if groundMaterialResetPolicy == .resetAlways || groundMaterialResetPolicy == .resetWithEachCell {
                    groundMaterial.reset()
                }
                let sprite = SKSpriteNode(texture: nil)
                sprite.anchorPoint = CGPoint(x: 0.5, y: 1)
                sprite.position = baseScenePosition
                
                let localGroundMaterialOverride = regionDescription.groundMaterialOverride(at: indexInRegion)
                groundMaterial.applyOn(spriteNode: sprite, withLocalOverrides: localGroundMaterialOverride)
                
                sprite.attributeValues = [
                    CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: WorldPosition(Float(mapX), Float(mapY), zForShader)),
                    CiderKitEngine.ShaderAttributeName.sizeAndFlip.rawValue: SKAttributeValue(vectorFloat4: SIMD4(WorldPosition(1, 1, 0), 0))
                ]
                
                addChild(sprite)
                
                let entity = map!.mapCellEntity(node: sprite, for: self, atMapPosition: MapPosition(x: mapX, y: mapY, elevation: elevation))
                if let cellComponent = entity.component(ofType: MapCellComponent.self) {
                    cellComponent.groundMaterialOverrides = localGroundMaterialOverride
                    cellComponent.leftElevationMaterialOverrides = localLeftElevationMaterialOverride
                    cellComponent.rightElevationMaterialOverrides = localRightElevationMaterialOverride
                }
                cellEntities.append(entity)
            }
        }

        regionDescription.assetPlacements?.forEach {
            if $0.mapPosition.elevation == nil {
                $0.mapPosition = $0.mapPosition.withElevation(regionDescription.elevation)
            }
            self.instantiateAsset(placement: $0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func containsMapCoordinates(mapX x: Int, y: Int) -> Bool { regionDescription.area.contains(mapX: x, y: y) }
    
    public static func < (lhs: MapRegion, rhs: MapRegion) -> Bool {
        let lhsArea = lhs.regionDescription.area
        let rhsArea = rhs.regionDescription.area
        
        let regionsOverlapOnX = (lhsArea.maxX > rhsArea.minX && lhsArea.minX < rhsArea.maxX)
        let regionsOverlapOnY = (lhsArea.maxY > rhsArea.minY && lhsArea.minY < rhsArea.maxY)
        
        var result: Bool
        if regionsOverlapOnX {
            result = lhsArea.minY < rhsArea.minY
        }
        else if regionsOverlapOnY {
            result = lhsArea.minX < rhsArea.minX
        }
        else {
            result = (lhsArea.minX + lhsArea.minY) < (rhsArea.minX + rhsArea.minY)
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

    @discardableResult
    private func instantiateAsset(placement: AssetPlacement) -> AssetInstance? {
        if let (instance, _) = map?.instantiateAsset(placement: placement) {
            addChild(instance.node!)
            assetInstances.append(instance)
            return instance
        }
        return nil
    }

    public func isLocationValidAndFreeOfAssets(mapPosition: MapPosition, footprint: SIMD2<UInt32>) -> Bool {
        do {
            return try checkLocationPreconditions(mapPosition: mapPosition, footprint: footprint)
        }
        catch {
            return false
        }
    }

    private func checkLocationPreconditions(mapPosition: MapPosition, footprint: SIMD2<UInt32>) throws -> Bool {
        let localCoords = regionDescription.area.convert(fromMapPosition: mapPosition)
        let minimalFootprint = localCoords &+ IntPoint.one

        guard minimalFootprint.x >= footprint.x, minimalFootprint.y >= footprint.y else {
            throw MapRegionErrors.assetTooCloseToRegionBorder
        }

        let assetArea = MapArea(x: mapPosition.x - Int(footprint.x), y: mapPosition.y - Int(footprint.y), width: Int(footprint.x), height: Int(footprint.y))
        guard regionDescription.isFreeOfAsset(mapArea: assetArea) else {
            throw MapRegionErrors.otherAssetInTheWay
        }

        return true
    }

    @discardableResult
    public func addAsset(_ asset: AssetLocator, named name: String, atMapPosition mapPosition: MapPosition, horizontallyFlipped: Bool) throws -> AssetInstance? {
        var footprint = asset.assetDescription!.footprint
        if horizontallyFlipped {
            footprint.flip()
        }
        guard try checkLocationPreconditions(mapPosition: mapPosition, footprint: footprint) else { return nil }

        regionDescription.assetPlacements = regionDescription.assetPlacements ?? []
        
        let placement = AssetPlacement(assetLocator: asset, horizontallyFlipped: horizontallyFlipped, position: mapPosition, name: name)
        regionDescription.assetPlacements!.append(placement)
        
        return instantiateAsset(placement: placement)
    }

    public func add(assetInstance: AssetInstance) throws {
        guard try checkLocationPreconditions(mapPosition: assetInstance.placement.mapPosition, footprint: assetInstance.assetDescription.footprint) else { return }

        regionDescription.assetPlacements = regionDescription.assetPlacements ?? []
        regionDescription.assetPlacements!.append(assetInstance.placement)
        addChild(assetInstance.node!)
    }

    public func remove(assetInstance: AssetInstance) {
        regionDescription.assetPlacements?.removeAll { $0 === assetInstance.placement }
        assetInstance.node?.removeFromParent()
    }

}
