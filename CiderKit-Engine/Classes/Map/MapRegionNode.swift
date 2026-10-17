import SpriteKit
import GameplayKit

public class MapRegionNode : SKNode {

    public private(set) var regionDescription: MapRegionDescription

    public private(set) var cellEntities: [GKEntity] = []
    private var assetInstances: [UUID: AssetInstance] = [:]

    var layerCount: Int { 4 }

    private let leftElevationRoot = SKNode()
    private var leftElevationNodes = [IntPoint: [SKSpriteNode]]()
    private let rightElevationRoot = SKNode()
    private var rightElevationNodes = [IntPoint: [SKSpriteNode]]()
    private let groundRoot = SKNode()
    private var groundNodes = [IntPoint: SKSpriteNode]()
    private let assetsRoot = SKNode()

    var map: MapNode? { parent as? MapNode }

    public init(for regionDescription: MapRegionDescription) {
        self.regionDescription = regionDescription

        super.init()

        addChild(leftElevationRoot)
        addChild(rightElevationRoot)
        addChild(groundRoot)
        addChild(assetsRoot)
    }

    func build(in mapDescription: SendableRef<MapDescription>) {
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
                let mapPoint = IntPoint(x, y)

                var localLeftElevationMaterialOverride: CustomSettings? = nil
                var localRightElevationMaterialOverride: CustomSettings? = nil
                
                let indexInRegion = y * regionDescription.area.width + x
                let mapY = y + Int(regionDescription.area.minY)

                let baseWorldPosition = WorldPosition(mapPoint: mapPoint, elevation: regionDescription.elevation)
                let baseScenePosition = MapNode.worldToScene(baseWorldPosition)

                let zForShader = Float(regionDescription.elevation)
                
                if renderer.leftElevationMaterialResetPolicy == .resetWithEachCell {
                    leftElevationMaterial.reset()
                }
                let leftElevationCount = mapDescription.ref.getLeftVisibleElevation(forX: mapX, y: mapY, usingDefaultElevation: regionDescription.elevation)
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
                    
                    leftElevationRoot.addChild(sprite)

                    if var nodeList = leftElevationNodes[mapPoint] {
                        nodeList.append(sprite)
                        leftElevationNodes[mapPoint] = nodeList
                    }
                    else {
                        leftElevationNodes[mapPoint] = [sprite]
                    }
                }

                if renderer.rightElevationMaterialResetPolicy == .resetWithEachCell {
                    rightElevationMaterial.reset()
                }
                let rightElevationCount = mapDescription.ref.getRightVisibleElevation(forX: mapX, y: mapY, usingDefaultElevation: regionDescription.elevation)
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
                    
                    rightElevationRoot.addChild(sprite)

                    if var nodeList = rightElevationNodes[mapPoint] {
                        nodeList.append(sprite)
                        rightElevationNodes[mapPoint] = nodeList
                    }
                    else {
                        rightElevationNodes[mapPoint] = [sprite]
                    }
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

                groundRoot.addChild(sprite)
                groundNodes[mapPoint] = sprite

                let entity = map!.mapCellEntity(node: sprite, for: self, atMapPosition: MapPosition(x: mapX, y: mapY, elevation: regionDescription.elevation))
                if let cellComponent = entity.components.first(where: { $0 is MapCellComponent }) as? MapCellComponent {
                    cellComponent.groundMaterialOverrides = localGroundMaterialOverride
                    cellComponent.leftElevationMaterialOverrides = localLeftElevationMaterialOverride
                    cellComponent.rightElevationMaterialOverrides = localRightElevationMaterialOverride
                }
                cellEntities.append(entity)
            }
        }
    }

    func match(regionDescription newRegionDescription: MapRegionDescription, in map: SendableRef<MapDescription>) {
        let oldRegionDescription = regionDescription
        regionDescription = newRegionDescription

        // TODO: Update asset instances

        if oldRegionDescription.elevation != regionDescription.elevation {
            let rendererName = regionDescription.renderer ?? "default_cell"
            let renderer = try! CellRenderers[rendererName]

            let leftElevationMaterial = try! renderer.leftElevationMaterial
            if renderer.leftElevationMaterialResetPolicy == .resetWithEachRegion {
                leftElevationMaterial.reset()
            }

            let rightElevationMaterial = try! renderer.rightElevationMaterial
            if renderer.leftElevationMaterialResetPolicy == .resetWithEachRegion {
                rightElevationMaterial.reset()
            }

            let zForShader = Float(regionDescription.elevation)

            // Left elevation
            for x in 0..<regionDescription.area.width {
                let mapPoint = IntPoint(x + regionDescription.area.minX, regionDescription.area.minY)
                let indexInRegion = mapPoint.y * regionDescription.area.width + mapPoint.x

                let previousVisibleElevation = leftElevationNodes[mapPoint]?.count ?? 0
                let visibleElevation = map.ref.getLeftVisibleElevation(forX: mapPoint.x, y: mapPoint.y, usingDefaultElevation: regionDescription.elevation)
                guard previousVisibleElevation != visibleElevation else { continue }

                var nodes = leftElevationNodes[mapPoint] ?? []

                if previousVisibleElevation > visibleElevation {
                    nodes.removeSubrange(0..<(previousVisibleElevation - visibleElevation))
                }
                else if previousVisibleElevation < visibleElevation {
                    let baseWorldPosition = WorldPosition(mapPoint: mapPoint, elevation: regionDescription.elevation)
                    let baseScenePosition = MapNode.worldToScene(baseWorldPosition)
                    for i in stride(from: visibleElevation - previousVisibleElevation - 1, through: 0, by: -1) {
                        let sprite = SKSpriteNode(texture: nil)
                        sprite.anchorPoint = CGPoint(x: 1, y: 1)
                        sprite.position = baseScenePosition + ScenePosition(x: 0, y: -MapNode.halfHeight - (i * MapNode.elevationHeight))
                        sprite.zPosition = -2

                        let z = zForShader - Float(i + 1)
                        sprite.attributeValues = [
                            CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: baseWorldPosition.with(z: z)),
                            CiderKitEngine.ShaderAttributeName.sizeAndFlip.rawValue: SKAttributeValue(vectorFloat4: SIMD4(WorldPosition(1, 1, 1), 0))
                        ]

                        nodes.insert(sprite, at: 0)
                    }
                }

                for i in 0..<nodes.count {
                    if renderer.leftElevationMaterialResetPolicy == .resetAlways {
                        leftElevationMaterial.reset()
                    }

                    let localLeftElevationMaterialOverride = regionDescription.leftElevationMaterialOverride(at: indexInRegion)
                    leftElevationMaterial.applyOn(spriteNode: nodes[i], withLocalOverrides: localLeftElevationMaterialOverride)
                }

                leftElevationNodes[mapPoint] = nodes
            }

            // Right elevation
            for y in 0..<regionDescription.area.height {
                let mapPoint = IntPoint(regionDescription.area.maxX - 1, y + regionDescription.area.minY)
                let indexInRegion = mapPoint.y * regionDescription.area.width + mapPoint.x

                let previousVisibleElevation = rightElevationNodes[mapPoint]?.count ?? 0
                let visibleElevation = map.ref.getRightVisibleElevation(forX: mapPoint.x, y: mapPoint.y, usingDefaultElevation: regionDescription.elevation)
                guard previousVisibleElevation != visibleElevation else { continue }

                var nodes = rightElevationNodes[mapPoint] ?? []

                if previousVisibleElevation > visibleElevation {
                    nodes.removeSubrange(0..<(previousVisibleElevation - visibleElevation))
                }
                else if previousVisibleElevation < visibleElevation {
                    let baseWorldPosition = WorldPosition(mapPoint: mapPoint, elevation: regionDescription.elevation)
                    let baseScenePosition = MapNode.worldToScene(baseWorldPosition)
                    for i in stride(from: visibleElevation - previousVisibleElevation - 1, through: 0, by: -1) {
                        let sprite = SKSpriteNode(texture: nil)
                        sprite.anchorPoint = CGPoint(x: 1, y: 1)
                        sprite.position = baseScenePosition + ScenePosition(x: 0, y: -MapNode.halfHeight - (i * MapNode.elevationHeight))
                        sprite.zPosition = -2

                        let z = zForShader - Float(i + 1)
                        sprite.attributeValues = [
                            CiderKitEngine.ShaderAttributeName.position.rawValue: SKAttributeValue(vectorFloat3: baseWorldPosition.with(z: z)),
                            CiderKitEngine.ShaderAttributeName.sizeAndFlip.rawValue: SKAttributeValue(vectorFloat4: SIMD4(WorldPosition(1, 1, 1), 0))
                        ]

                        nodes.insert(sprite, at: 0)
                    }
                }

                for i in 0..<nodes.count {
                    if renderer.rightElevationMaterialResetPolicy == .resetAlways {
                        rightElevationMaterial.reset()
                    }

                    let localRightElevationMaterialOverride = regionDescription.rightElevationMaterialOverride(at: indexInRegion)
                    rightElevationMaterial.applyOn(spriteNode: nodes[i], withLocalOverrides: localRightElevationMaterialOverride)
                }

                rightElevationNodes[mapPoint] = nodes
            }

            // Ground
            for (mapPoint, sprite) in groundNodes {
                let newWorldPos = WorldPosition(mapPoint: mapPoint, elevation: regionDescription.elevation)
                sprite.position = MapNode.worldToScene(newWorldPos)
            }

            // Cell entities
            for cellEntity in cellEntities {
                if let cellComponent = cellEntity.components.first(where: { $0 is MapCellComponent }) as? MapCellComponent {
                    cellComponent.position = cellComponent.position.with(elevation: regionDescription.elevation)
                }
            }
        }
    }

    func dismantle(detach: Bool = true) {
        cellEntities.removeAll()
        assetInstances.removeAll()

        leftElevationRoot.removeAllChildren()
        leftElevationNodes.removeAll()
        rightElevationRoot.removeAllChildren()
        rightElevationNodes.removeAll()
        groundRoot.removeAllChildren()
        groundNodes.removeAll()
        assetsRoot.removeAllChildren()

        if detach {
            removeFromParent()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func add(assetInstance: AssetInstance) {
        assetsRoot.addChild(assetInstance.node!)
        assetInstances[assetInstance.placement.id] = assetInstance
    }

    public func remove(assetInstance: AssetInstance) {
        assetInstances[assetInstance.placement.id] = nil
        assetInstance.node?.removeFromParent()
    }

}
