import SpriteKit
import GameplayKit

public class MapRegionNode : SKNode {
    
    public weak var regionModel: MapRegionModel?

    public private(set) var cellEntities: [GKEntity] = []
    public private(set) var assetInstances: [AssetInstance] = []
    
    var layerCount: Int { 10 }

    var map: MapNode? { parent as? MapNode }

    public init(for regionModel: MapRegionModel) {
        super.init()
        
        self.regionModel = regionModel
    }

    func build() {
        guard
            let regionDescription = regionModel?.regionDescription,
            let mapModel = regionModel?.map
        else { return }

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
                let leftElevationCount = mapModel.getLeftVisibleElevation(forX: mapX, y: mapY, usingDefaultElevation: regionDescription.elevation)
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
                let rightElevationCount = mapModel.getRightVisibleElevation(forX: mapX, y: mapY, usingDefaultElevation: regionDescription.elevation)
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
                
                let entity = map!.mapCellEntity(node: sprite, for: self, atMapPosition: MapPosition(x: mapX, y: mapY, elevation: regionDescription.elevation))
                if let cellComponent = entity.component(ofType: MapCellComponent.self) {
                    cellComponent.groundMaterialOverrides = localGroundMaterialOverride
                    cellComponent.leftElevationMaterialOverrides = localLeftElevationMaterialOverride
                    cellComponent.rightElevationMaterialOverrides = localRightElevationMaterialOverride
                }
                cellEntities.append(entity)
            }
        }

        regionDescription.assetPlacements.forEach {
            if $0.mapPosition.elevation == nil {
                $0.mapPosition = $0.mapPosition.with(elevation: regionDescription.elevation)
            }
            self.instantiateAsset(placement: $0)
        }
    }

    func dismantle() {
        cellEntities.removeAll()
        removeAllAssetInstances(includingPlacement: false)
        removeAllChildren()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    @discardableResult
    public func addAsset(_ asset: AssetLocator, named name: String, atMapPosition mapPosition: MapPosition, horizontallyFlipped: Bool) throws -> AssetInstance? {
        guard let regionModel else { return nil }

        var footprint = asset.assetDescription!.footprint
        if horizontallyFlipped {
            footprint.flip()
        }
        guard regionModel.isLocationValidAndFreeOfAssets(mapPosition: mapPosition, footprint: footprint) else { return nil }

        let placement = AssetPlacement(assetLocator: asset, horizontallyFlipped: horizontallyFlipped, position: mapPosition, name: name)
        regionModel.add(assetPlacement: placement)

        return instantiateAsset(placement: placement)
    }

    public func add(assetInstance: AssetInstance) throws {
        guard
            let regionModel,
            regionModel.isLocationValidAndFreeOfAssets(mapPosition: assetInstance.placement.mapPosition, footprint: assetInstance.assetDescription.footprint)
        else {
            return
        }

        regionModel.add(assetPlacement: assetInstance.placement)
        addChild(assetInstance.node!)
    }

    @discardableResult
    public func remove(assetInstance: AssetInstance, includingPlacement: Bool = true) -> Bool {
        assetInstances.removeAll { $0 === assetInstance }
        if includingPlacement {
            if regionModel?.remove(assetPlacement: assetInstance.placement) ?? false {
                assetInstance.node?.removeFromParent()
                return true
            }
        }
        else {
            assetInstance.node?.removeFromParent()
            return true
        }
        return false
    }

    public func removeAllAssetInstances(includingPlacement: Bool = true) {
        assetInstances.forEach { map?.remove(assetInstance: $0, includingPlacement: includingPlacement) }
        assetInstances.removeAll()
    }

}
